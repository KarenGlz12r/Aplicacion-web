-- Crear Base de Datos
CREATE DATABASE IF NOT EXISTS evaluacion;
USE evaluacion;

-- Tabla repartidor
CREATE TABLE IF NOT EXISTS repartidor (
    id_r INT AUTO_INCREMENT PRIMARY KEY,
    r_nomC VARCHAR(255) NOT NULL,
    r_correo VARCHAR(255) NOT NULL,
    r_pass VARCHAR(255) NOT NULL
);

-- Tabla paquetes
CREATE TABLE IF NOT EXISTS paquetes (
    id_pq INT AUTO_INCREMENT PRIMARY KEY,
    colonia VARCHAR(255) NOT NULL,
    calle VARCHAR(255) NOT NULL,
    numero INT NOT NULL,
    codigo_postal INT NOT NULL,
    destinatario VARCHAR(255) NOT NULL,
    estado ENUM('Sin entregar', 'Entregado') DEFAULT 'Sin entregar',
    id_rep INT NOT NULL,
    FOREIGN KEY (id_rep) REFERENCES repartidor(id_r)
);

-- Tabla entregas
CREATE TABLE IF NOT EXISTS entregas (
    id_e INT AUTO_INCREMENT PRIMARY KEY,
    id_p INT NOT NULL,
    id_re INT NOT NULL,
    latitud DECIMAL(10,7) NOT NULL,
    longitud DECIMAL(11,7) NOT NULL,
    direccion VARCHAR(255),
    ruta_foto VARCHAR(255),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_p) REFERENCES paquetes(id_pq),
    FOREIGN KEY (id_re) REFERENCES repartidor(id_r)
);

-- Tabla Admin
CREATE TABLE IF NOT EXISTS Admin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    correo VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL
);
-- insertar admin
INSERT INTO Admin (id, nombre, correo, password) VALUES 
(1, 'Gabriel', 'gabriel@example.com', '00ld7302lld');
