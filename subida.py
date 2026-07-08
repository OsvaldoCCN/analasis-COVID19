import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()


USER = os.getenv("DB_USER")
PASSWORD = os.getenv("DB_PASSWORD", "")
HOST = os.getenv("DB_HOST", "localhost")
PORT = os.getenv("DB_PORT", "3306")
DATABASE = os.getenv("DB_NAME")


engine = create_engine(f'mysql+mysqlconnector://{USER}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}')

csv_path = os.getenv("CSV_PATH")

if not csv_path:
    raise ValueError("La ruta del CSV (CSV_PATH) no está definida en el archivo .env")

print("Iniciando la carga de datos... Esto puede tardar cerca de 1 o 2 minutos.")


chunk_size = 100000
try:
    for i, chunk in enumerate(pd.read_csv(csv_path, chunksize=chunk_size)):
        chunk.to_sql('covid_raw', con=engine, if_exists='append', index=False)
        print(f"Bloque {i+1} cargado exitosamente ({(i+1)*chunk_size} filas procesadas)...")
        
    print("¡Proceso finalizado! Todos los datos están en la tabla covid_raw.")

except FileNotFoundError:
    print(f"Error: No se encontró el archivo CSV en la ruta especificada: {csv_path}")
except Exception as e:
    print(f"Ocurrió un error durante la carga: {e}")