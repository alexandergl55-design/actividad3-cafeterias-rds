# Actividad 3 — Aprovisionamiento IaaS/PaaS y carga analítica en Amazon RDS

**Herramientas de Computación en la Nube** · Maestría en Analítica Aplicada
Universidad de La Sabana

---

## Objetivo

Extender el pipeline de datos construido en la Actividad 2 con una capa de
almacenamiento estructurado. Los datos crudos de cafeterías de la localidad de
Teusaquillo, depositados en la zona cruda de Amazon S3, se leen desde un entorno
colaborativo JupyterHub sobre EC2, se transforman con pandas y se persisten en
un motor relacional administrado Amazon RDS PostgreSQL.

## Arquitectura

```
Foursquare Places API
        │
        ▼
Amazon S3 — raw-zone/cafeterias/          (zona cruda, Actividad 2)
        │
        ▼
Amazon EC2 t3.medium + JupyterHub (TLJH)  (IaaS — procesamiento)
        │  pandas: limpieza, tipificación, JSONB
        ▼
Amazon RDS PostgreSQL db.t3.micro         (PaaS — almacenamiento estructurado)
        │  INSERT parametrizados
        ▼
Estadísticas descriptivas + visualizaciones
```

## Contenido del repositorio

| Archivo | Descripción |
|---|---|
| `ddl_cafeterias_teusaquillo.sql` | Script DDL de la tabla, índices y documentación del modelo |
| `pipeline_s3_rds_cafeterias.ipynb` | Notebook con el pipeline completo: S3 → transformación → RDS → análisis |
| `GUIA_PASO_A_PASO.md` | Procedimiento de aprovisionamiento de la infraestructura |
| `docs/modelo_entidad_relacion.png` | Modelo entidad-relación de la tabla |
| `.env.ejemplo` | Plantilla de variables de entorno (sin valores sensibles) |
| `requirements.txt` | Dependencias de Python |
| `.gitignore` | Exclusión de credenciales y datos |

## Modelo de datos

Tabla `cafeterias_teusaquillo` (46 registros):

| Columna | Tipo | Justificación |
|---|---|---|
| `fsq_place_id` | `VARCHAR(40)` PK | Identificador natural provisto por Foursquare |
| `name` | `VARCHAR(255)` | Nombre comercial |
| `latitude` / `longitude` | `DOUBLE PRECISION` | Precisión requerida para coordenadas WGS84 |
| `distance_m` | `INTEGER` | Distancia en metros, valor discreto |
| `primary_category` | `VARCHAR(100)` | Categoría principal, indexada |
| `categories` | `JSONB` | Atributo multivaluado; índice GIN para consultas de contención |
| `category_ids` | `JSONB` | Identificadores de categoría, paralelo al anterior |
| `address` | `TEXT` | Longitud variable; admite nulos |
| `localidad` | `VARCHAR(100)` | Localidad validada geográficamente |
| `fecha_carga` | `TIMESTAMP` | Trazabilidad del proceso de carga |

### Por qué JSONB

Un establecimiento puede pertenecer a varias categorías simultáneamente
(`Coffee Shop` + `Bakery`, `Café` + `Coworking Space`). Modelarlo con `JSONB`
evita una tabla puente adicional y, con el índice GIN, habilita consultas de
contención eficientes:

```sql
SELECT name FROM cafeterias_teusaquillo
WHERE categories @> '["Bakery"]';
```

## Seguridad

- **Confianza cero**: ninguna credencial está escrita en el código. Todas se
  leen desde variables de entorno (`.env`), archivo excluido del control de
  versiones.
- **Acceso a S3 sin llaves estáticas**: la instancia EC2 obtiene permisos del
  rol IAM `LabInstanceProfile`.
- **Cortafuegos virtual**: el grupo de seguridad de RDS autoriza el puerto 5432
  únicamente desde la IP del equipo de desarrollo y desde el grupo de seguridad
  de las instancias EC2.
- **Prevención de inyección SQL**: todas las inserciones usan consultas
  parametrizadas (`%s`), nunca concatenación de cadenas.

## Reproducción

1. Sigue `GUIA_PASO_A_PASO.md` para aprovisionar RDS, el grupo de seguridad y
   la instancia EC2 con JupyterHub.
2. Copia `.env.ejemplo` como `.env` y completa los valores.
3. Ejecuta `ddl_cafeterias_teusaquillo.sql` desde DBeaver.
4. Ejecuta `pipeline_s3_rds_cafeterias.ipynb` en JupyterHub.

## Fuente de los datos

Conjunto de 46 cafeterías de la localidad de Teusaquillo extraídas de Foursquare
Places API durante la Actividad 2, depuradas y validadas contra el polígono
oficial de la localidad.
