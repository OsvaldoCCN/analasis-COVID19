-- =====================================================================
-- MODELO DIMENSIONAL COVID-19
-- =====================================================================

USE tarea3;

-- =====================================================================
-- 0. ELIMINACIÓN
-- =====================================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS fact_mortalidad;
DROP TABLE IF EXISTS fact_atencion;

DROP TABLE IF EXISTS dim_tiempo;
DROP TABLE IF EXISTS dim_clasificacion;
DROP TABLE IF EXISTS dim_perfil_clinico;
DROP TABLE IF EXISTS dim_institucion_medica;
DROP TABLE IF EXISTS dim_demografia;


SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- 1. DIMENSIONES
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1.1 DIM_DEMOGRAFIA
-- Jerarquía: etapa_vida -> grupo_etario -> edad
-- ---------------------------------------------------------------------

CREATE TABLE dim_demografia (
    id_demografia INT AUTO_INCREMENT PRIMARY KEY,
    sexo           VARCHAR(20) NOT NULL,
    embarazo       VARCHAR(20) NOT NULL,
    edad           INT         NOT NULL,
    grupo_etario   VARCHAR(20) NOT NULL,
    etapa_vida     VARCHAR(30) NOT NULL,

    UNIQUE KEY uq_demografia (sexo, embarazo, edad)
);

INSERT INTO dim_demografia (
    sexo,
    embarazo,
    edad,
    grupo_etario,
    etapa_vida
)
SELECT DISTINCT
    CASE
        WHEN SEX = 1 THEN 'Mujer'
        WHEN SEX = 2 THEN 'Hombre'
        ELSE 'No especificado'
    END AS sexo,

    CASE
        WHEN SEX = 2 THEN 'No aplica'
        WHEN PREGNANT = 1 THEN 'Sí'
        WHEN PREGNANT = 2 THEN 'No'
        ELSE 'No especificado'
    END AS embarazo,

    CASE
        WHEN AGE IS NULL OR AGE < 0 OR AGE > 120 THEN -1
        ELSE AGE
    END AS edad,

    CASE
        WHEN AGE IS NULL OR AGE < 0 OR AGE > 120 THEN 'No especificado'
        WHEN AGE < 18 THEN '0-17'
        WHEN AGE BETWEEN 18 AND 39 THEN '18-39'
        WHEN AGE BETWEEN 40 AND 59 THEN '40-59'
        ELSE '60+'
    END AS grupo_etario,

    CASE
        WHEN AGE IS NULL OR AGE < 0 OR AGE > 120 THEN 'No especificado'
        WHEN AGE < 18 THEN 'Niñez y adolescencia'
        WHEN AGE BETWEEN 18 AND 59 THEN 'Adultez'
        ELSE 'Adulto mayor'
    END AS etapa_vida
FROM covid_raw;


-- ---------------------------------------------------------------------
-- 1.2 DIM_INSTITUCION_MEDICA
-- ---------------------------------------------------------------------

CREATE TABLE dim_institucion_medica (
    id_institucion           INT AUTO_INCREMENT PRIMARY KEY,
    usmer_codigo             SMALLINT    NOT NULL,
    usmer_descripcion        VARCHAR(30) NOT NULL,
    medical_unit_codigo      SMALLINT    NOT NULL,
    medical_unit_descripcion VARCHAR(40) NOT NULL,

    UNIQUE KEY uq_institucion (
        usmer_codigo,
        medical_unit_codigo
    )
);

INSERT INTO dim_institucion_medica (
    usmer_codigo,
    usmer_descripcion,
    medical_unit_codigo,
    medical_unit_descripcion
)
SELECT DISTINCT
    COALESCE(USMER, -1),

    CASE
        WHEN USMER IS NULL THEN 'No especificado'
        ELSE CONCAT('Código USMER ', USMER)
    END,

    COALESCE(MEDICAL_UNIT, -1),

    CASE
        WHEN MEDICAL_UNIT IS NULL THEN 'No especificado'
        ELSE CONCAT('Unidad médica código ', MEDICAL_UNIT)
    END
FROM covid_raw;


-- ---------------------------------------------------------------------
-- 1.3 DIM_PERFIL_CLINICO
-- ---------------------------------------------------------------------

CREATE TABLE dim_perfil_clinico (
    id_perfil_clinico INT AUTO_INCREMENT PRIMARY KEY,

    diabetes_codigo        SMALLINT NOT NULL,
    epoc_codigo            SMALLINT NOT NULL,
    asma_codigo            SMALLINT NOT NULL,
    inmunosupresion_codigo SMALLINT NOT NULL,
    hipertension_codigo    SMALLINT NOT NULL,
    cardiovascular_codigo SMALLINT NOT NULL,
    obesidad_codigo        SMALLINT NOT NULL,
    renal_cronica_codigo   SMALLINT NOT NULL,
    otra_enfermedad_codigo SMALLINT NOT NULL,
    tabaquismo_codigo      SMALLINT NOT NULL,

    diabetes        VARCHAR(20) NOT NULL,
    epoc            VARCHAR(20) NOT NULL,
    asma            VARCHAR(20) NOT NULL,
    inmunosupresion VARCHAR(20) NOT NULL,
    hipertension    VARCHAR(20) NOT NULL,
    cardiovascular VARCHAR(20) NOT NULL,
    obesidad        VARCHAR(20) NOT NULL,
    renal_cronica   VARCHAR(20) NOT NULL,
    otra_enfermedad VARCHAR(20) NOT NULL,
    tabaquismo      VARCHAR(20) NOT NULL,

    n_comorbilidades_confirmadas       TINYINT     NOT NULL,
    n_comorbilidades_no_especificadas  TINYINT     NOT NULL,
    nivel_carga_comorbilidad           VARCHAR(30) NOT NULL,

    UNIQUE KEY uq_perfil_clinico (
        diabetes_codigo,
        epoc_codigo,
        asma_codigo,
        inmunosupresion_codigo,
        hipertension_codigo,
        cardiovascular_codigo,
        obesidad_codigo,
        renal_cronica_codigo,
        otra_enfermedad_codigo,
        tabaquismo_codigo
    )
);

INSERT INTO dim_perfil_clinico (
    diabetes_codigo,
    epoc_codigo,
    asma_codigo,
    inmunosupresion_codigo,
    hipertension_codigo,
    cardiovascular_codigo,
    obesidad_codigo,
    renal_cronica_codigo,
    otra_enfermedad_codigo,
    tabaquismo_codigo,

    diabetes,
    epoc,
    asma,
    inmunosupresion,
    hipertension,
    cardiovascular,
    obesidad,
    renal_cronica,
    otra_enfermedad,
    tabaquismo,

    n_comorbilidades_confirmadas,
    n_comorbilidades_no_especificadas,
    nivel_carga_comorbilidad
)
SELECT DISTINCT
    p.diabetes_codigo,
    p.epoc_codigo,
    p.asma_codigo,
    p.inmunosupresion_codigo,
    p.hipertension_codigo,
    p.cardiovascular_codigo,
    p.obesidad_codigo,
    p.renal_cronica_codigo,
    p.otra_enfermedad_codigo,
    p.tabaquismo_codigo,

    p.diabetes,
    p.epoc,
    p.asma,
    p.inmunosupresion,
    p.hipertension,
    p.cardiovascular,
    p.obesidad,
    p.renal_cronica,
    p.otra_enfermedad,
    p.tabaquismo,

    p.n_comorbilidades_confirmadas,
    p.n_comorbilidades_no_especificadas,

    CASE
        WHEN p.n_comorbilidades_no_especificadas > 0
            THEN 'Información incompleta'
        WHEN p.n_comorbilidades_confirmadas = 0
            THEN 'Sin comorbilidades'
        WHEN p.n_comorbilidades_confirmadas BETWEEN 1 AND 2
            THEN '1 a 2 comorbilidades'
        ELSE '3 o más comorbilidades'
    END
FROM (
    SELECT
        COALESCE(DIABETES, -1)       AS diabetes_codigo,
        COALESCE(COPD, -1)           AS epoc_codigo,
        COALESCE(ASTHMA, -1)         AS asma_codigo,
        COALESCE(INMSUPR, -1)        AS inmunosupresion_codigo,
        COALESCE(HIPERTENSION, -1)   AS hipertension_codigo,
        COALESCE(CARDIOVASCULAR, -1) AS cardiovascular_codigo,
        COALESCE(OBESITY, -1)        AS obesidad_codigo,
        COALESCE(RENAL_CHRONIC, -1)  AS renal_cronica_codigo,
        COALESCE(OTHER_DISEASE, -1)  AS otra_enfermedad_codigo,
        COALESCE(TOBACCO, -1)        AS tabaquismo_codigo,

        CASE WHEN DIABETES = 1 THEN 'Sí'
             WHEN DIABETES = 2 THEN 'No'
             ELSE 'No especificado' END AS diabetes,

        CASE WHEN COPD = 1 THEN 'Sí'
             WHEN COPD = 2 THEN 'No'
             ELSE 'No especificado' END AS epoc,

        CASE WHEN ASTHMA = 1 THEN 'Sí'
             WHEN ASTHMA = 2 THEN 'No'
             ELSE 'No especificado' END AS asma,

        CASE WHEN INMSUPR = 1 THEN 'Sí'
             WHEN INMSUPR = 2 THEN 'No'
             ELSE 'No especificado' END AS inmunosupresion,

        CASE WHEN HIPERTENSION = 1 THEN 'Sí'
             WHEN HIPERTENSION = 2 THEN 'No'
             ELSE 'No especificado' END AS hipertension,

        CASE WHEN CARDIOVASCULAR = 1 THEN 'Sí'
             WHEN CARDIOVASCULAR = 2 THEN 'No'
             ELSE 'No especificado' END AS cardiovascular,

        CASE WHEN OBESITY = 1 THEN 'Sí'
             WHEN OBESITY = 2 THEN 'No'
             ELSE 'No especificado' END AS obesidad,

        CASE WHEN RENAL_CHRONIC = 1 THEN 'Sí'
             WHEN RENAL_CHRONIC = 2 THEN 'No'
             ELSE 'No especificado' END AS renal_cronica,

        CASE WHEN OTHER_DISEASE = 1 THEN 'Sí'
             WHEN OTHER_DISEASE = 2 THEN 'No'
             ELSE 'No especificado' END AS otra_enfermedad,

        CASE WHEN TOBACCO = 1 THEN 'Sí'
             WHEN TOBACCO = 2 THEN 'No'
             ELSE 'No especificado' END AS tabaquismo,

        (
            CASE WHEN DIABETES = 1 THEN 1 ELSE 0 END +
            CASE WHEN COPD = 1 THEN 1 ELSE 0 END +
            CASE WHEN ASTHMA = 1 THEN 1 ELSE 0 END +
            CASE WHEN INMSUPR = 1 THEN 1 ELSE 0 END +
            CASE WHEN HIPERTENSION = 1 THEN 1 ELSE 0 END +
            CASE WHEN CARDIOVASCULAR = 1 THEN 1 ELSE 0 END +
            CASE WHEN OBESITY = 1 THEN 1 ELSE 0 END +
            CASE WHEN RENAL_CHRONIC = 1 THEN 1 ELSE 0 END +
            CASE WHEN OTHER_DISEASE = 1 THEN 1 ELSE 0 END
        ) AS n_comorbilidades_confirmadas,

        (
            CASE WHEN DIABETES IN (1, 2) THEN 0 ELSE 1 END +
            CASE WHEN COPD IN (1, 2) THEN 0 ELSE 1 END +
            CASE WHEN ASTHMA IN (1, 2) THEN 0 ELSE 1 END +
            CASE WHEN INMSUPR IN (1, 2) THEN 0 ELSE 1 END +
            CASE WHEN HIPERTENSION IN (1, 2) THEN 0 ELSE 1 END +
            CASE WHEN CARDIOVASCULAR IN (1, 2) THEN 0 ELSE 1 END +
            CASE WHEN OBESITY IN (1, 2) THEN 0 ELSE 1 END +
            CASE WHEN RENAL_CHRONIC IN (1, 2) THEN 0 ELSE 1 END +
            CASE WHEN OTHER_DISEASE IN (1, 2) THEN 0 ELSE 1 END
        ) AS n_comorbilidades_no_especificadas
    FROM covid_raw
) AS p;


-- ---------------------------------------------------------------------
-- 1.4 DIM_CLASIFICACION
-- Jerarquía: resultado_general -> detalle_clasificacion
-- ---------------------------------------------------------------------

CREATE TABLE dim_clasificacion (
    id_clasificacion      INT AUTO_INCREMENT PRIMARY KEY,
    codigo                SMALLINT    NOT NULL,
    resultado_general     VARCHAR(40) NOT NULL,
    detalle_clasificacion VARCHAR(40) NOT NULL,

    UNIQUE KEY uq_clasificacion (codigo)
);

INSERT INTO dim_clasificacion (
    codigo,
    resultado_general,
    detalle_clasificacion
)
SELECT DISTINCT
    COALESCE(CLASIFFICATION_FINAL, -1),

    CASE
        WHEN CLASIFFICATION_FINAL IN (1, 2, 3)
            THEN 'Positivo'
        WHEN CLASIFFICATION_FINAL >= 4
            THEN 'No portador o inconcluyente'
        ELSE 'No especificado'
    END,

    CASE
        WHEN CLASIFFICATION_FINAL IS NULL
            THEN 'Clasificación no especificada'
        ELSE CONCAT('Clasificación ', CLASIFFICATION_FINAL)
    END
FROM covid_raw;


-- ---------------------------------------------------------------------
-- 1.5 DIM_TIEMPO
-- Jerarquía: año -> trimestre -> mes -> día
-- ---------------------------------------------------------------------

CREATE TABLE dim_tiempo (
    id_tiempo  INT PRIMARY KEY,
    fecha      DATE        NOT NULL,
    anio       SMALLINT    NOT NULL,
    trimestre  TINYINT     NOT NULL,
    mes        TINYINT     NOT NULL,
    nombre_mes VARCHAR(15) NOT NULL,
    anio_mes   CHAR(7)     NOT NULL,
    dia        TINYINT     NOT NULL,

    UNIQUE KEY uq_tiempo_fecha (fecha)
);

INSERT INTO dim_tiempo (
    id_tiempo,
    fecha,
    anio,
    trimestre,
    mes,
    nombre_mes,
    anio_mes,
    dia
)
SELECT
    CAST(DATE_FORMAT(f.fecha, '%Y%m%d') AS UNSIGNED),
    f.fecha,
    YEAR(f.fecha),
    QUARTER(f.fecha),
    MONTH(f.fecha),

    CASE MONTH(f.fecha)
        WHEN 1 THEN 'Enero'
        WHEN 2 THEN 'Febrero'
        WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Mayo'
        WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'
        WHEN 11 THEN 'Noviembre'
        WHEN 12 THEN 'Diciembre'
    END,

    DATE_FORMAT(f.fecha, '%Y-%m'),
    DAY(f.fecha)
FROM (
    SELECT DISTINCT
        CASE
            WHEN DATE_DIED REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
                THEN STR_TO_DATE(
                    NULLIF(DATE_DIED, '9999-99-99'),
                    '%d/%m/%Y'
                )

            WHEN DATE_DIED REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                THEN STR_TO_DATE(
                    NULLIF(DATE_DIED, '9999-99-99'),
                    '%Y-%m-%d'
                )

            ELSE NULL
        END AS fecha
    FROM covid_raw
) AS f
WHERE f.fecha IS NOT NULL;


-- =====================================================================
-- 2. TABLAS DE HECHOS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 2.1 FACT_ATENCION
-- Grano: una fila por registro de covid_raw.
-- ---------------------------------------------------------------------

CREATE TABLE fact_atencion (
    id_fact_atencion     BIGINT AUTO_INCREMENT PRIMARY KEY,

    id_demografia_fk     INT NOT NULL,
    id_institucion_fk    INT NOT NULL,
    id_perfil_clinico_fk INT NOT NULL,
    id_clasificacion_fk  INT NOT NULL,

    es_hospitalizado     TINYINT NULL,
    es_uci               TINYINT NULL,
    es_intubado          TINYINT NULL,
    tiene_neumonia       TINYINT NULL,
    cantidad_pacientes   TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT fk_fa_demografia
        FOREIGN KEY (id_demografia_fk)
        REFERENCES dim_demografia(id_demografia),

    CONSTRAINT fk_fa_institucion
        FOREIGN KEY (id_institucion_fk)
        REFERENCES dim_institucion_medica(id_institucion),

    CONSTRAINT fk_fa_perfil
        FOREIGN KEY (id_perfil_clinico_fk)
        REFERENCES dim_perfil_clinico(id_perfil_clinico),

    CONSTRAINT fk_fa_clasificacion
        FOREIGN KEY (id_clasificacion_fk)
        REFERENCES dim_clasificacion(id_clasificacion),

    INDEX ix_fa_demografia (id_demografia_fk),
    INDEX ix_fa_institucion (id_institucion_fk),
    INDEX ix_fa_perfil (id_perfil_clinico_fk),
    INDEX ix_fa_clasificacion (id_clasificacion_fk)
);

INSERT INTO fact_atencion (
    id_demografia_fk,
    id_institucion_fk,
    id_perfil_clinico_fk,
    id_clasificacion_fk,
    es_hospitalizado,
    es_uci,
    es_intubado,
    tiene_neumonia,
    cantidad_pacientes
)
SELECT
    dd.id_demografia,
    di.id_institucion,
    dp.id_perfil_clinico,
    dc.id_clasificacion,

    CASE
        WHEN r.PATIENT_TYPE = 2 THEN 1
        WHEN r.PATIENT_TYPE = 1 THEN 0
        ELSE NULL
    END,

    CASE
        WHEN r.ICU = 1 THEN 1
        WHEN r.ICU = 2 THEN 0
        ELSE NULL
    END,

    CASE
        WHEN r.INTUBED = 1 THEN 1
        WHEN r.INTUBED = 2 THEN 0
        ELSE NULL
    END,

    CASE
        WHEN r.PNEUMONIA = 1 THEN 1
        WHEN r.PNEUMONIA = 2 THEN 0
        ELSE NULL
    END,

    1
FROM covid_raw AS r

INNER JOIN dim_demografia AS dd
    ON dd.sexo =
       CASE
           WHEN r.SEX = 1 THEN 'Mujer'
           WHEN r.SEX = 2 THEN 'Hombre'
           ELSE 'No especificado'
       END

   AND dd.embarazo =
       CASE
           WHEN r.SEX = 2 THEN 'No aplica'
           WHEN r.PREGNANT = 1 THEN 'Sí'
           WHEN r.PREGNANT = 2 THEN 'No'
           ELSE 'No especificado'
       END

   AND dd.edad =
       CASE
           WHEN r.AGE IS NULL OR r.AGE < 0 OR r.AGE > 120 THEN -1
           ELSE r.AGE
       END

INNER JOIN dim_institucion_medica AS di
    ON di.usmer_codigo = COALESCE(r.USMER, -1)
   AND di.medical_unit_codigo = COALESCE(r.MEDICAL_UNIT, -1)

INNER JOIN dim_perfil_clinico AS dp
    ON dp.diabetes_codigo = COALESCE(r.DIABETES, -1)
   AND dp.epoc_codigo = COALESCE(r.COPD, -1)
   AND dp.asma_codigo = COALESCE(r.ASTHMA, -1)
   AND dp.inmunosupresion_codigo = COALESCE(r.INMSUPR, -1)
   AND dp.hipertension_codigo = COALESCE(r.HIPERTENSION, -1)
   AND dp.cardiovascular_codigo = COALESCE(r.CARDIOVASCULAR, -1)
   AND dp.obesidad_codigo = COALESCE(r.OBESITY, -1)
   AND dp.renal_cronica_codigo = COALESCE(r.RENAL_CHRONIC, -1)
   AND dp.otra_enfermedad_codigo = COALESCE(r.OTHER_DISEASE, -1)
   AND dp.tabaquismo_codigo = COALESCE(r.TOBACCO, -1)

INNER JOIN dim_clasificacion AS dc
    ON dc.codigo = COALESCE(r.CLASIFFICATION_FINAL, -1);


-- ---------------------------------------------------------------------
-- 2.2 FACT_MORTALIDAD
-- Grano: una fila por registro con fecha de fallecimiento válida.
-- ---------------------------------------------------------------------

CREATE TABLE fact_mortalidad (
    id_fact_mortalidad   BIGINT AUTO_INCREMENT PRIMARY KEY,

    id_demografia_fk     INT NOT NULL,
    id_institucion_fk    INT NOT NULL,
    id_perfil_clinico_fk INT NOT NULL,
    id_clasificacion_fk  INT NOT NULL,
    id_tiempo_fk         INT NOT NULL,

    cantidad_fallecidos  TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT fk_fm_demografia
        FOREIGN KEY (id_demografia_fk)
        REFERENCES dim_demografia(id_demografia),

    CONSTRAINT fk_fm_institucion
        FOREIGN KEY (id_institucion_fk)
        REFERENCES dim_institucion_medica(id_institucion),

    CONSTRAINT fk_fm_perfil
        FOREIGN KEY (id_perfil_clinico_fk)
        REFERENCES dim_perfil_clinico(id_perfil_clinico),

    CONSTRAINT fk_fm_clasificacion
        FOREIGN KEY (id_clasificacion_fk)
        REFERENCES dim_clasificacion(id_clasificacion),

    CONSTRAINT fk_fm_tiempo
        FOREIGN KEY (id_tiempo_fk)
        REFERENCES dim_tiempo(id_tiempo),

    INDEX ix_fm_demografia (id_demografia_fk),
    INDEX ix_fm_institucion (id_institucion_fk),
    INDEX ix_fm_perfil (id_perfil_clinico_fk),
    INDEX ix_fm_clasificacion (id_clasificacion_fk),
    INDEX ix_fm_tiempo (id_tiempo_fk)
);

INSERT INTO fact_mortalidad (
    id_demografia_fk,
    id_institucion_fk,
    id_perfil_clinico_fk,
    id_clasificacion_fk,
    id_tiempo_fk,
    cantidad_fallecidos
)
SELECT
    dd.id_demografia,
    di.id_institucion,
    dp.id_perfil_clinico,
    dc.id_clasificacion,
    dt.id_tiempo,
    1
FROM (
    SELECT
        cr.*,

        CASE
            WHEN cr.DATE_DIED REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
                THEN STR_TO_DATE(
                    NULLIF(cr.DATE_DIED, '9999-99-99'),
                    '%d/%m/%Y'
                )

            WHEN cr.DATE_DIED REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                THEN STR_TO_DATE(
                    NULLIF(cr.DATE_DIED, '9999-99-99'),
                    '%Y-%m-%d'
                )

            ELSE NULL
        END AS fecha_fallecimiento

    FROM covid_raw AS cr
) AS r

INNER JOIN dim_demografia AS dd
    ON dd.sexo =
       CASE
           WHEN r.SEX = 1 THEN 'Mujer'
           WHEN r.SEX = 2 THEN 'Hombre'
           ELSE 'No especificado'
       END

   AND dd.embarazo =
       CASE
           WHEN r.SEX = 2 THEN 'No aplica'
           WHEN r.PREGNANT = 1 THEN 'Sí'
           WHEN r.PREGNANT = 2 THEN 'No'
           ELSE 'No especificado'
       END

   AND dd.edad =
       CASE
           WHEN r.AGE IS NULL OR r.AGE < 0 OR r.AGE > 120 THEN -1
           ELSE r.AGE
       END

INNER JOIN dim_institucion_medica AS di
    ON di.usmer_codigo = COALESCE(r.USMER, -1)
   AND di.medical_unit_codigo = COALESCE(r.MEDICAL_UNIT, -1)

INNER JOIN dim_perfil_clinico AS dp
    ON dp.diabetes_codigo = COALESCE(r.DIABETES, -1)
   AND dp.epoc_codigo = COALESCE(r.COPD, -1)
   AND dp.asma_codigo = COALESCE(r.ASTHMA, -1)
   AND dp.inmunosupresion_codigo = COALESCE(r.INMSUPR, -1)
   AND dp.hipertension_codigo = COALESCE(r.HIPERTENSION, -1)
   AND dp.cardiovascular_codigo = COALESCE(r.CARDIOVASCULAR, -1)
   AND dp.obesidad_codigo = COALESCE(r.OBESITY, -1)
   AND dp.renal_cronica_codigo = COALESCE(r.RENAL_CHRONIC, -1)
   AND dp.otra_enfermedad_codigo = COALESCE(r.OTHER_DISEASE, -1)
   AND dp.tabaquismo_codigo = COALESCE(r.TOBACCO, -1)

INNER JOIN dim_clasificacion AS dc
    ON dc.codigo = COALESCE(r.CLASIFFICATION_FINAL, -1)

INNER JOIN dim_tiempo AS dt
    ON dt.fecha = r.fecha_fallecimiento

WHERE r.fecha_fallecimiento IS NOT NULL;


-- =====================================================================
-- 3. VERIFICACIONES
-- =====================================================================

SELECT 'covid_raw' AS tabla, COUNT(*) AS cantidad
FROM covid_raw

UNION ALL

SELECT 'dim_demografia', COUNT(*)
FROM dim_demografia

UNION ALL

SELECT 'dim_institucion_medica', COUNT(*)
FROM dim_institucion_medica

UNION ALL

SELECT 'dim_perfil_clinico', COUNT(*)
FROM dim_perfil_clinico

UNION ALL

SELECT 'dim_clasificacion', COUNT(*)
FROM dim_clasificacion

UNION ALL

SELECT 'dim_tiempo', COUNT(*)
FROM dim_tiempo

UNION ALL

SELECT 'fact_atencion', COUNT(*)
FROM fact_atencion

UNION ALL

SELECT 'fact_mortalidad', COUNT(*)
FROM fact_mortalidad;


SELECT
    (SELECT COUNT(*) FROM covid_raw) AS filas_raw,
    (SELECT COUNT(*) FROM fact_atencion) AS filas_fact_atencion,
    (SELECT COUNT(*) FROM covid_raw)
      - (SELECT COUNT(*) FROM fact_atencion) AS diferencia;


SELECT
    dc.resultado_general,
    SUM(fm.cantidad_fallecidos) AS total_fallecidos
FROM fact_mortalidad AS fm
INNER JOIN dim_clasificacion AS dc
    ON dc.id_clasificacion = fm.id_clasificacion_fk
GROUP BY dc.resultado_general
ORDER BY total_fallecidos DESC;
