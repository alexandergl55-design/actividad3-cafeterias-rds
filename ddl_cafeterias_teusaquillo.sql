-- =====================================================================
-- Script DDL - Tabla de cafeterias de Teusaquillo
-- Actividad 3 - Herramientas de Computacion en la Nube
-- Maestria en Analitica Aplicada - Universidad de La Sabana
-- Autor: Efren Alexander Granados Latorre
-- Motor: PostgreSQL (Amazon RDS - db.t3.micro)
-- Fuente de datos: Foursquare Places API
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Creacion de la tabla
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS cafeterias_teusaquillo;

CREATE TABLE cafeterias_teusaquillo (
    fsq_place_id          VARCHAR(40)      PRIMARY KEY,
    name                  VARCHAR(255)     NOT NULL,
    latitude              DOUBLE PRECISION NOT NULL,
    longitude             DOUBLE PRECISION NOT NULL,
    distance_m            INTEGER,
    primary_category      VARCHAR(100),
    primary_category_id   VARCHAR(40),
    categories            JSONB,
    category_ids          JSONB,
    address               TEXT,
    localidad             VARCHAR(100),
    fecha_carga           TIMESTAMP        DEFAULT CURRENT_TIMESTAMP,

    -- Restricciones de dominio
    CONSTRAINT chk_latitud   CHECK (latitude  BETWEEN -90  AND 90),
    CONSTRAINT chk_longitud  CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT chk_distancia CHECK (distance_m >= 0)
);

-- ---------------------------------------------------------------------
-- 2. Indices
-- ---------------------------------------------------------------------

-- Consultas por categoria principal (Coffee Shop / Cafe)
CREATE INDEX idx_cafeterias_categoria
    ON cafeterias_teusaquillo (primary_category);

-- Consultas por localidad (permite extender el modelo a otras localidades)
CREATE INDEX idx_cafeterias_localidad
    ON cafeterias_teusaquillo (localidad);

-- Indice GIN: busquedas dentro del arreglo JSONB de categorias
-- Ejemplo de uso: WHERE categories @> '["Bakery"]'
CREATE INDEX idx_cafeterias_categories_gin
    ON cafeterias_teusaquillo USING GIN (categories);

-- Indice compuesto para filtros geoespaciales por rango de coordenadas
CREATE INDEX idx_cafeterias_coords
    ON cafeterias_teusaquillo (latitude, longitude);

-- ---------------------------------------------------------------------
-- 3. Documentacion del modelo
-- ---------------------------------------------------------------------
COMMENT ON TABLE cafeterias_teusaquillo IS
    'Establecimientos de categoria cafeteria (Coffee Shop / Cafe) ubicados en la localidad de Teusaquillo, Bogota. Datos extraidos de Foursquare Places API y validados contra el poligono oficial de la localidad.';

COMMENT ON COLUMN cafeterias_teusaquillo.fsq_place_id IS
    'Identificador unico del establecimiento asignado por Foursquare. Clave primaria natural.';
COMMENT ON COLUMN cafeterias_teusaquillo.name IS
    'Nombre comercial del establecimiento.';
COMMENT ON COLUMN cafeterias_teusaquillo.latitude IS
    'Latitud en grados decimales (WGS84).';
COMMENT ON COLUMN cafeterias_teusaquillo.longitude IS
    'Longitud en grados decimales (WGS84).';
COMMENT ON COLUMN cafeterias_teusaquillo.distance_m IS
    'Distancia en metros desde el punto central utilizado en la consulta a la API.';
COMMENT ON COLUMN cafeterias_teusaquillo.primary_category IS
    'Categoria principal asignada por Foursquare.';
COMMENT ON COLUMN cafeterias_teusaquillo.primary_category_id IS
    'Identificador de la categoria principal en la taxonomia de Foursquare.';
COMMENT ON COLUMN cafeterias_teusaquillo.categories IS
    'Arreglo JSONB con todas las categorias del establecimiento. Modela el atributo multivaluado sin requerir una tabla adicional.';
COMMENT ON COLUMN cafeterias_teusaquillo.category_ids IS
    'Arreglo JSONB con los identificadores de las categorias, en el mismo orden que el campo categories.';
COMMENT ON COLUMN cafeterias_teusaquillo.address IS
    'Direccion registrada del establecimiento. Admite nulos: no todos los registros de la API la reportan.';
COMMENT ON COLUMN cafeterias_teusaquillo.localidad IS
    'Localidad de Bogota en la que se ubica el establecimiento, validada geograficamente.';
COMMENT ON COLUMN cafeterias_teusaquillo.fecha_carga IS
    'Marca de tiempo del proceso de carga a la base de datos.';

-- ---------------------------------------------------------------------
-- 4. Verificacion de la estructura creada
-- ---------------------------------------------------------------------
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'cafeterias_teusaquillo'
-- ORDER BY ordinal_position;
