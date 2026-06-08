"""
===========================================================================
Python + PostgreSQL con FastAPI
===========================================================================

Este archivo es INTENCIONALMENTE monolítico para que veas todo el flujo
de conexión a base de datos en un solo lugar.

FLUJO DE CONEXIÓN:
1. psycopg2 → Driver que permite a Python hablar con PostgreSQL
2. DATABASE_URL → Cadena de conexión con credenciales y host
3. get_db() → Función que crea y cierra conexiones (pool básico)
4. SQL directo → Queries crudos para ver exactamente qué se ejecuta
"""

import os
import psycopg2
from psycopg2.extras import RealDictCursor
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import date
import re

# ============================================================================
# CONFIGURACIÓN DE CONEXIÓN
# ============================================================================
# psycopg2 es el "puente" entre Python y PostgreSQL.
# Necesita: host, puerto, usuario, password, nombre de base de datos.
# Todo viene en una sola URL que leemos del environment (del docker-compose).

DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://alumno:123456@my-database:5432/db-personas"
)

# ============================================================================
# CONEXIÓN A LA BASE DE DATOS
# ============================================================================
# get_db() es un "generador" que:
#   1. Abre una conexión cuando alguien la necesita
#   2. La entrega para usarla
#   3. La cierra automáticamente cuando termina (incluso si hay error)
#
# RealDictCursor permite acceder a las columnas por nombre: row['nombre']
# en vez de por índice: row[0]

def get_db():
    """
    Generador de conexiones a PostgreSQL.
    Se usa con Depends() en FastAPI para inyección de dependencias.
    """
    conn = psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)
    try:
        yield conn
    finally:
        conn.close()


# ============================================================================
# MODELOS PYDANTIC (Validación de datos de entrada)
# ============================================================================
# Pydantic valida AUTOMÁTICAMENTE antes de que llegue a tu código.
# Si el usuario manda datos mal, FastAPI devuelve error 422 sin que hagas nada.

class PersonaCreate(BaseModel):
    """Modelo para CREAR persona. Todos los campos son obligatorios."""
    nombre: str = Field(..., min_length=1, max_length=50)
    primer_apellido: str = Field(..., min_length=1, max_length=50)
    segundo_apellido: Optional[str] = Field(None, max_length=50)
    ci: str = Field(..., min_length=1, max_length=20)

    @field_validator('ci')
    @classmethod
    def ci_solo_numeros(cls, v):
        """Validación custom: CI debe ser solo dígitos."""
        if not re.match(r'^\d+$', v):
            raise ValueError('CI debe contener solo números')
        return v

    @field_validator('nombre', 'primer_apellido', 'segundo_apellido')
    @classmethod
    def solo_letras(cls, v):
        """Validación custom: nombres solo letras y espacios."""
        if v is not None and not re.match(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$', v):
            raise ValueError('Solo se permiten letras y espacios')
        return v.strip() if v else v


class ViajeCreate(BaseModel):
    """Modelo para CREAR viaje. Requiere persona existente y país existente."""
    persona_id: int = Field(..., gt=0, description="ID de persona que viaja")
    pais_id: int = Field(..., gt=0, description="ID del país destino")
    fecha_llegada: date = Field(..., description="Fecha de llegada")

    @field_validator('fecha_llegada')
    @classmethod
    def no_futuro(cls, v):
        """Validación custom: no permitir fechas futuras."""
        if v > date.today():
            raise ValueError('La fecha no puede ser futura')
        return v


# ============================================================================
# APLICACIÓN FASTAPI
# ============================================================================

app = FastAPI(
    title="Python + PostgreSQL",
    description="Ejemplo mínimo para comprender la conexión a BD",
    version="1.0"
)


@app.get("/")
def root():
    """Endpoint de bienvenida. Lista qué puedes hacer."""
    return {
        "mensaje": "Tutorial Python + PostgreSQL",
        "endpoints": {
            "POST /personas": "Crear persona",
            "GET /personas": "Listar personas",
            "DELETE /personas/{id}": "Eliminar persona + sus viajes",
            "POST /viajes": "Crear viaje (necesita persona_id y pais_id)",
            "GET /viajes": "Listar viajes"
        }
    }


# ============================================================================
# CRUD PERSONAS
# ============================================================================

@app.post("/personas", status_code=201)
def crear_persona(persona: PersonaCreate, db=Depends(get_db)):
    """
    CREAR persona.
    
    SQL ejecutado:
        INSERT INTO personas (nombre, primer_apellido, segundo_apellido, ci)
        VALUES (%s, %s, %s, %s) RETURNING *
    
    %s son "placeholders" que psycopg2 escapa automáticamente.
    Esto previene SQL INJECTION.
    """
    cursor = db.cursor()
    try:
        cursor.execute(
            """
            INSERT INTO personas (nombre, primer_apellido, segundo_apellido, ci)
            VALUES (%s, %s, %s, %s)
            RETURNING *
            """,
            (persona.nombre, persona.primer_apellido, persona.segundo_apellido, persona.ci)
        )
        db.commit()  # ¡IMPORTANTE! Sin commit, los cambios no se guardan.
        return cursor.fetchone()
    except psycopg2.IntegrityError:
        db.rollback()  # Si falla (CI duplicado), deshacemos todo.
        raise HTTPException(status_code=400, detail=f"CI {persona.ci} ya existe")
    finally:
        cursor.close()




@app.post("/personas_ps", status_code=201)
def crear_persona_ps(persona: PersonaCreate, db=Depends(get_db)):
    cursor = db.cursor()
    try:
        # CALL para PROCEDURE
        cursor.execute(
            "CALL sp_crear_persona(%s, %s, %s, %s)",
            (persona.nombre, persona.primer_apellido, persona.segundo_apellido, persona.ci)
        )
        db.commit()
        
        # Como el SP no retorna nada, hacemos SELECT
        cursor.execute(
            "SELECT * FROM personas WHERE ci = %s",
            (persona.ci,)
        )
        return cursor.fetchone()
        
    except psycopg2.IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"CI {persona.ci} ya existe")
    finally:
        cursor.close()





@app.get("/personas")
def listar_personas(db=Depends(get_db)):
    """
    LISTAR todas las personas.
    
    SQL: SELECT * FROM personas
    """
    cursor = db.cursor()
    cursor.execute("SELECT * FROM personas ORDER BY persona_id")
    resultados = cursor.fetchall()
    cursor.close()
    return resultados


@app.delete("/personas/{persona_id}")
def eliminar_persona(persona_id: int, db=Depends(get_db)):
    """
    ELIMINAR persona y TODOS sus viajes automáticamente.
    
    Gracias a ON DELETE CASCADE en la foreign key de viajes.persona_id,
    PostgreSQL borra los viajes de esa persona automáticamente.
    
    SQL:
        DELETE FROM personas WHERE persona_id = %s
    """
    cursor = db.cursor()
    
    # Verificar que existe
    cursor.execute("SELECT * FROM personas WHERE persona_id = %s", (persona_id,))
    persona = cursor.fetchone()
    
    if not persona:
        cursor.close()
        raise HTTPException(status_code=404, detail="Persona no encontrada")
    
    # Eliminar (los viajes se borran solos por CASCADE)
    cursor.execute("DELETE FROM personas WHERE persona_id = %s RETURNING *", (persona_id,))
    eliminada = cursor.fetchone()
    db.commit()
    cursor.close()
    
    return {
        "mensaje": "Persona eliminada",
        "persona": eliminada,
        "nota": "Sus viajes también fueron eliminados por CASCADE"
    }


# ============================================================================
# CRUD VIAJES
# ============================================================================

@app.post("/viajes", status_code=201)
def crear_viaje(viaje: ViajeCreate, db=Depends(get_db)):
    """
    CREAR viaje.
    
    Verificamos manualmente que persona_id y pais_id existen
    antes de insertar (integridad referencial).
    """
    cursor = db.cursor()
    
    # Verificar que la persona existe
    cursor.execute("SELECT persona_id FROM personas WHERE persona_id = %s", (viaje.persona_id,))
    if not cursor.fetchone():
        cursor.close()
        raise HTTPException(status_code=404, detail="Persona no existe")
    
    # Verificar que el país existe
    cursor.execute("SELECT pais_id FROM paises WHERE pais_id = %s", (viaje.pais_id,))
    if not cursor.fetchone():
        cursor.close()
        raise HTTPException(status_code=404, detail="País no existe")
    
    # Insertar viaje
    cursor.execute(
        """
        INSERT INTO viajes (persona_id, pais_id, fecha_llegada)
        VALUES (%s, %s, %s)
        RETURNING *
        """,
        (viaje.persona_id, viaje.pais_id, viaje.fecha_llegada)
    )
    db.commit()
    nuevo_viaje = cursor.fetchone()
    cursor.close()
    
    return nuevo_viaje


@app.get("/viajes")
def listar_viajes(db=Depends(get_db)):
    """
    LISTAR viajes con info de persona y país (JOIN).
    
    SQL con JOIN para traer datos relacionados en una sola query.
    """
    cursor = db.cursor()
    cursor.execute("""
        SELECT 
            v.viaje_id,
            v.fecha_llegada,
            p.nombre || ' ' || p.primer_apellido as persona,
            pa.pais_nombre as pais
        FROM viajes v
        JOIN personas p ON v.persona_id = p.persona_id
        JOIN paises pa ON v.pais_id = pa.pais_id
        ORDER BY v.viaje_id
    """)
    resultados = cursor.fetchall()
    cursor.close()
    return resultados