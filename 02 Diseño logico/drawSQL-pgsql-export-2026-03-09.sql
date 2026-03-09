CREATE TABLE "linea"(
    "color" CHAR(255) NOT NULL,
    "fecha_inaguracion" DATE NOT NULL
);
ALTER TABLE
    "linea" ADD PRIMARY KEY("color");
CREATE TABLE "estacion"(
    "nombre" VARCHAR(255) NOT NULL,
    "direccion" BIGINT NOT NULL
);
ALTER TABLE
    "estacion" ADD PRIMARY KEY("nombre");
CREATE TABLE "empleado"(
    "carnet" VARCHAR(255) NOT NULL,
    "nombre" VARCHAR(255) NOT NULL,
    "sueldo" DOUBLE PRECISION NOT NULL
);
ALTER TABLE
    "empleado" ADD PRIMARY KEY("carnet");
CREATE TABLE "telefono"(
    "id" BIGINT NOT NULL,
    "fk_carnet" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "telefono" ADD PRIMARY KEY("id");
CREATE TABLE "recorre"(
    "id" BIGINT NOT NULL,
    "fk_color_linea" VARCHAR(255) NOT NULL,
    "fk_nombre_estacion" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "recorre" ADD PRIMARY KEY("id");
CREATE TABLE "cabina"(
    "numero_cabina" BIGINT NOT NULL,
    "fk_color_linea" BIGINT NOT NULL
);
ALTER TABLE
    "cabina" ADD PRIMARY KEY("numero_cabina");
CREATE TABLE "pasajero"(
    "carnet" VARCHAR(255) NOT NULL,
    "nombre" VARCHAR(255) NOT NULL,
    "primer_apellido" VARCHAR(255) NOT NULL,
    "segundo_apellido" VARCHAR(255) NOT NULL,
    "edad" INTEGER NOT NULL
);
ALTER TABLE
    "pasajero" ADD PRIMARY KEY("carnet");
CREATE TABLE "bono"(
    "codigo_beneficiario" BIGINT NOT NULL,
    "fk_carnet_pasajero" BIGINT NOT NULL
);
ALTER TABLE
    "bono" ADD PRIMARY KEY("codigo_beneficiario");
CREATE TABLE "transporta"(
    "id" BIGINT NOT NULL,
    "fk_numero_cabina" BIGINT NOT NULL,
    "fk_carnet_pasajero" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "transporta" ADD PRIMARY KEY("id");
ALTER TABLE
    "cabina" ADD CONSTRAINT "cabina_fk_color_linea_foreign" FOREIGN KEY("fk_color_linea") REFERENCES "linea"("color");
ALTER TABLE
    "telefono" ADD CONSTRAINT "telefono_fk_carnet_foreign" FOREIGN KEY("fk_carnet") REFERENCES "empleado"("carnet");
ALTER TABLE
    "recorre" ADD CONSTRAINT "recorre_fk_color_linea_foreign" FOREIGN KEY("fk_color_linea") REFERENCES "linea"("color");
ALTER TABLE
    "transporta" ADD CONSTRAINT "transporta_fk_carnet_pasajero_foreign" FOREIGN KEY("fk_carnet_pasajero") REFERENCES "pasajero"("carnet");
ALTER TABLE
    "recorre" ADD CONSTRAINT "recorre_fk_nombre_estacion_foreign" FOREIGN KEY("fk_nombre_estacion") REFERENCES "estacion"("nombre");
ALTER TABLE
    "bono" ADD CONSTRAINT "bono_fk_carnet_pasajero_foreign" FOREIGN KEY("fk_carnet_pasajero") REFERENCES "pasajero"("carnet");
ALTER TABLE
    "empleado" ADD CONSTRAINT "empleado_carnet_foreign" FOREIGN KEY("carnet") REFERENCES "estacion"("nombre");
ALTER TABLE
    "transporta" ADD CONSTRAINT "transporta_fk_numero_cabina_foreign" FOREIGN KEY("fk_numero_cabina") REFERENCES "cabina"("numero_cabina");