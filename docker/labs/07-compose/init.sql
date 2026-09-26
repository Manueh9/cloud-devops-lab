-- Se ejecuta SOLO la primera vez que se inicializa un volumen vacio.
-- Crea la estructura, no los datos.
CREATE TABLE IF NOT EXISTS certificados (
    id     SERIAL PRIMARY KEY,
    alumno TEXT,
    curso  TEXT,
    fecha  DATE
);
