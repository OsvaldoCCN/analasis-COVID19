# Análisis COVID-19

Proyecto de análisis de datos COVID-19 con carga de datos desde CSV hacia MySQL, creación de un modelo dimensional y visualización en Power BI.

## Contenido del proyecto

- `Covid_Data.csv`: dataset base que se carga en MySQL.
- `subida.py`: script de Python que lee el CSV por bloques y lo inserta en la tabla `covid_raw`.
- `script.sql`: script SQL que crea dimensiones, tablas de hechos y consultas de verificación.
- `RESPALDO.sql`: respaldo SQL de la base de datos.
- `tarea3_final.pbix`: reporte de Power BI.
- `.env`: variables locales para conectar Python con MySQL.

## Requisitos

- Python 3.10 o superior.
- MySQL Server en ejecución.
- Power BI Desktop, solo si quieres abrir el archivo `.pbix`.

Dependencias de Python:

```bash
pip install pandas sqlalchemy python-dotenv mysql-connector-python
```

## 1. Crear la base de datos en MySQL

Entra a MySQL con tu usuario:

```bash
mysql -u tu_usuario -p
```

Crea la base de datos usada por el proyecto:

```sql
-- Esquema para el Staging / Datos crudos
CREATE DATABASE IF NOT EXISTS tarea3_raw;

-- Esquema para el Data Warehouse (Modelos en Estrella)
CREATE DATABASE IF NOT EXISTS tarea3;
USE tarea3;
```
Luego sal de MySQL:

```sql
EXIT;
```

## 2. Configurar variables de entorno

Edita el archivo `.env` con tus credenciales locales de MySQL y la ruta correcta del CSV.

Ejemplo para macOS/Linux:

```env
DB_USER=tu_usuario
DB_PASSWORD=tu_password
DB_HOST=localhost
DB_PORT=3306
DB_NAME=tarea3_raw
CSV_PATH=/Users/yoko/Dev/analasis-COVID19/Covid_Data.csv
```

Ejemplo para Windows:

```env
DB_USER=tu_usuario
DB_PASSWORD=tu_password
DB_HOST=localhost
DB_PORT=3306
DB_NAME=tarea3_raw
CSV_PATH=C:\ruta\a\tu\proyecto\Covid_Data.csv
```

## 3. Cargar el CSV en MySQL

Ejecuta el script de carga:

```bash
python subida.py
```

El script crea o reutiliza la tabla `covid_raw` e inserta los datos por bloques de `100000` filas. La carga puede tardar unos minutos porque el archivo CSV es grande.

Si todo sale bien, verás mensajes similares a:

```text
Iniciando la carga de datos... Esto puede tardar cerca de 1 o 2 minutos.
Bloque 1 cargado exitosamente...
¡Proceso finalizado! Todos los datos están en la tabla covid_raw.
```

## 4. Crear el modelo dimensional

Cuando la tabla `covid_raw` ya tenga datos, ejecuta el script SQL:

```bash
mysql -u tu_usuario -p tarea3 < script.sql
```

Este script crea y llena:

- `dim_demografia`
- `dim_institucion_medica`
- `dim_perfil_clinico`
- `dim_clasificacion`
- `dim_tiempo`
- `fact_atencion`
- `fact_mortalidad`

Al final también ejecuta consultas de verificación con conteos de registros.

## 5. Abrir el reporte en Power BI

Abre `tarea3_final.pbix` con Power BI Desktop.

Si Power BI pide actualizar la conexión, usa los mismos datos de MySQL configurados en `.env`:

- Servidor: `localhost`
- Puerto: `3306`
- Base de datos: `tarea3`
- Usuario y contraseña: tus credenciales locales de MySQL

## Restaurar desde respaldo

Si prefieres restaurar la base desde `RESPALDO.sql`, puedes hacerlo con:

```bash
mysql -u tu_usuario -p tarea3 < RESPALDO.sql
```

Usa esta alternativa si ya tienes el respaldo completo y no quieres volver a cargar el CSV ni ejecutar todo el modelo desde cero.

## Solución de problemas

Si aparece un error como `Access denied`, revisa que `DB_USER` y `DB_PASSWORD` sean correctos.

Si aparece `Unknown database 'tarea3'`, crea primero la base de datos con:

```sql
CREATE DATABASE tarea3;
```

Si aparece `No se encontró el archivo CSV`, revisa que `CSV_PATH` apunte a la ubicación real de `Covid_Data.csv`.

Si aparece un error relacionado con `mysqlconnector`, instala la dependencia:

```bash
pip install mysql-connector-python
```
