CREATE DATABASE IF NOT EXISTS tortas_mariluz 

/* para desacrivar modo seguro */
SET SQL_SAFE_UPDATES = 0;

USE tortas_mariluz

CREATE TABLE IF NOT EXISTS productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY, 
    nombre VARCHAR(30) NOT NULL,
    descripcion VARCHAR(150) NULL DEFAULT "Sin Descripcion",
    precio_unitario DECIMAL NOT NULL,
    tipo_producto VARCHAR(30) NOT NULL,  -- "Torta", "cupcake", "tarta", etc
    disponible ENUM("Disponible", "No Disponible") NOT NULL
);

CREATE TABLE IF NOT EXISTS clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL, 
    apellido VARCHAR(30) NOT NULL,
    dni INT NOT NULL, 
    telefono INT NOT NULL
);

CREATE TABLE IF NOT EXISTS pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_pedido DATE,         -- tiene CURRENT_DATE
    fecha_entrega DATE NOT NULL,
    total DECIMAL NOT NULL,
    estado_pago ENUM('Pendiente', 'Pagado', 'Parcial') NOT NULL,
    estado_entrega ENUM('Pendiente', 'Entregado', 'Cancelado') NOT NULL,
    FOREIGN key (id_cliente) REFERENCES clientes(id_cliente)
);

/* Tabla intermedia entre pedidos y productos */
CREATE TABLE IF NOT EXISTS detalles_pedido (
    id_pedido INT NOT NULL, 
    id_producto INT NOT NULL,
    cantidad INT NOT NULL, 
    precio_unitario DECIMAL,
    comentario VARCHAR(100) NULL DEFAULT "Sin Comentario",    -- si desea algun extra en el producto (decoracion)
    PRIMARY KEY (id_pedido, id_producto),
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE IF NOT EXISTS pagos (
    id_pago INT AUTO_INCREMENT PRIMARY key, 
    id_pedido INT NOT NULL, 
    fecha_pago DATE,        -- tiene CURRENT_DATE
    monto_pagado DECIMAL NOT NULL,
    metodo_pagado VARCHAR(30) NOT NULL,
    FOREIGN key (id_pedido) REFERENCES pedidos(id_pedido)
);

CREATE TABLE IF NOT EXISTS ingredientes (
    id_ingrediente INT AUTO_INCREMENT PRIMARY key,
    nombre VARCHAR(30) NOT NULL, 
    unidad_medida VARCHAR(30) NULL, 
    stock_actual DECIMAL NULL 
);

/* Tabla intermedia entre productos y ingredientes */
CREATE TABLE IF NOT EXISTS recetas (
    id_producto INT NOT NULL, 
    id_ingrediente INT NOT NULL, 
    cantidad_usada DECIMAL NOT NULL,
    unidad_medida VARCHAR(30) NULL,
    comentario VARCHAR(100) NULL DEFAULT "Sin Comentarios",    -- Indicar como se dividen las cantidades en caso de usar el mismo ingrediente dos veces en la receta
    PRIMARY KEY (id_producto, id_ingrediente),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto), 
    FOREIGN KEY (id_ingrediente) REFERENCES ingredientes(id_ingrediente)
);

-- ALTER TABLE
ALTER TABLE pedidos 
MODIFY fecha_pedido DATE DEFAULT (CURRENT_DATE);

ALTER TABLE pagos 
MODIFY fecha_pago DATE DEFAULT (CURRENT_DATE);

-- Vistas
-- Creacion de vista 
CREATE VIEW view_productos AS SELECT id_producto, nombre, tipo_producto, disponible FROM tortas_mariluz.productos;
CREATE VIEW view_clientes AS SELECT nombre, apellido, telefono FROM tortas_mariluz.clientes;
CREATE VIEW view_pedidos AS SELECT id_pedido, id_cliente, total FROM tortas_mariluz.pedidos ;
CREATE VIEW view_ingredientes AS SELECT nombre, stock_actual FROM tortas_mariluz.ingredientes ;
-- detalles pedido todo menos el monto

-- Usar la vista 
/* id_producto, nombre, tipo_producto y disponible */
SELECT * FROM view_productos ;

/* nombre apellido y tel del cliente */
SELECT * FROM view_clientes;

/* id_pedido, id_cliente y el total */
SELECT * FROM view_pedidos;

/* nombre y stock del ingrediente */
SELECT * FROM view_ingredientes;

/* Entrega 2 */
/* Agregamos columnas a la tabla pedidos */
ALTER TABLE 
pedidos ADD COLUMN estado_pago ENUM('Pendiente', 'Pagado', 'Parcial') NOT NULL DEFAULT "Pendiente", 
ADD COLUMN estado_entrega ENUM('Pendiente', 'Entregado', 'Cancelado') NOT NULL DEFAULT "Pendiente";

/* Actualizamos la columna disponible de la tabla productos */
UPDATE productos
SET disponible = CASE
    WHEN disponible = 1 THEN 'Disponible'
END;

/* Pedidos 1, 2 y 3, Pagados */
UPDATE pedidos SET estado_pago = 'Pagado' WHERE id_pedido IN (1, 2, 3);

-- UPDATES
UPDATE detalles_pedido SET comentario = "Sin Comentarios" WHERE comentario = "Sin Decoracion extra"
UPDATE recetas SET comentario = "Sin Comentarios" WHERE comentario is null;