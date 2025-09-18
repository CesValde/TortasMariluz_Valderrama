CREATE DATABASE IF NOT EXISTS tortas_mariluz ;

/* para desacrivar modo seguro */
SET SQL_SAFE_UPDATES = 0;

USE tortas_mariluz ;

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
    fecha_pedido DATE DEFAULT (CURRENT_DATE),
    fecha_entrega DATE NOT NULL,
    total DECIMAL NOT NULL,
    estado_pago ENUM('Pendiente', 'Pagado', 'Parcial') NOT NULL DEFAULT "Pendiente",
    estado_entrega ENUM('Pendiente', 'Entregado', 'Cancelado') NOT NULL DEFAULT "Pendiente",
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
    fecha_pago DATE DEFAULT (CURRENT_DATE),
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

CREATE TABLE IF NOT EXISTS empleados (
    id_empleado INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    usuario VARCHAR(30) UNIQUE NOT NULL,
    contrasena VARCHAR(100) NOT NULL,
    rol ENUM('Admin', 'Ventas', 'Producción') NOT NULL
);

CREATE TABLE IF NOT EXISTS proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(50)
);

/* Tabla intermedia entre proveedores y ingredientes */
CREATE TABLE IF NOT EXISTS compras (
    id_compra INT AUTO_INCREMENT PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_ingrediente INT NOT NULL,
    cantidad DECIMAL NOT NULL,      /* Cantidad en KG */
    precio_unitario DECIMAL(10,2) NOT NULL,
    fecha_compra DATE NOT NULL DEFAULT (CURRENT_DATE),
    FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor),
    FOREIGN KEY (id_ingrediente) REFERENCES ingredientes(id_ingrediente)
);

CREATE TABLE IF NOT EXISTS promociones (
    id_promocion INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    tipo ENUM('Porcentaje', 'Monto Fijo') NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE
);

-- Vistas
-- Creacion de vista 
CREATE VIEW view_productos AS 
SELECT id_producto, nombre, tipo_producto, disponible 
FROM tortas_mariluz.productos
ORDER BY disponible ASC ;

CREATE VIEW view_clientes AS 
SELECT nombre, apellido, telefono 
FROM tortas_mariluz.clientes
ORDER BY nombre ASC ;

CREATE VIEW view_pedidos AS 
SELECT id_pedido, id_cliente, total 
FROM tortas_mariluz.pedidos 
WHERE estado_pago = "Pagado" ;

CREATE VIEW view_ingredientes AS SELECT nombre, stock_actual FROM tortas_mariluz.ingredientes ;
CREATE VIEW view_detalles_pedido AS SELECT id_pedido, id_producto, cantidad, comentario FROM tortas_mariluz.detalles_pedido ;

CREATE VIEW view_promociones AS
SELECT nombre, tipo, valor
FROM tortas_mariluz.promociones
ORDER BY valor DESC
LIMIT 1;

/* Consultas Join */

/* devuelve solo los ingredientes que estén asignados a algún producto */
SELECT r.id_producto, i.nombre AS ingrediente, r.cantidad_usada, r.unidad_medida, r.comentario
FROM recetas r
INNER JOIN ingredientes i ON r.id_ingrediente = i.id_ingrediente;

/* todos los ingredientes aunque no estén en ninguna receta */
SELECT i.id_ingrediente, i.nombre, r.id_producto, r.cantidad_usada
FROM ingredientes i
LEFT JOIN recetas r ON i.id_ingrediente = r.id_ingrediente;

-- Usar la vista 
/* id_producto, nombre, tipo_producto y disponible */
SELECT * FROM view_productos ;

/* nombre apellido y tel del cliente */
SELECT * FROM view_clientes;

/* id_pedido, id_cliente y el total */
SELECT * FROM view_pedidos;

/* nombre y stock del ingrediente */
SELECT * FROM view_ingredientes;

/* id_prodcuto, id_pedido, cantidad, y comentario */
SELECT * FROM view_detalles_pedido;

/* Ver que pedidos tienen mas de 1 producto1 */
SELECT id_pedido, COUNT(id_producto) AS productos_distintos
FROM view_detalles_pedido
GROUP BY id_pedido
HAVING productos_distintos > 1;

/* nombre, tipo, valor */
SELECT * FROM view_promociones ;

-- Stored Producers 
-- Creacion de Stored Producers 
DELIMITER $$

CREATE PROCEDURE registrar_pago (
    IN p_id_pedido INT,
    IN p_monto DECIMAL(10,2),
    IN p_metodo VARCHAR(30)
)
BEGIN
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_pagado DECIMAL(10,2);

    -- Insertar el pago
    INSERT INTO pagos (id_pedido, fecha_pago, monto_pagado, metodo_pagado)
    VALUES (p_id_pedido, CURRENT_DATE, p_monto, p_metodo);

    -- Calcular cuánto lleva pagado
    SELECT IFNULL(SUM(monto_pagado),0) INTO v_pagado
    FROM pagos
    WHERE id_pedido = p_id_pedido;

    -- Traer total del pedido
    SELECT total INTO v_total
    FROM pedidos
    WHERE id_pedido = p_id_pedido;

    -- Actualizar estado
    IF v_pagado >= v_total THEN
        UPDATE pedidos SET estado_pago = 'Pagado'
        WHERE id_pedido = p_id_pedido;
    ELSEIF v_pagado > 0 AND v_pagado <= (v_total / 2) THEN 
        UPDATE pedidos SET estado_pago = 'Parcial'
        WHERE id_pedido = p_id_pedido;
    ELSE
        UPDATE pedidos SET estado_pago = 'Pendiente'
        WHERE id_pedido = p_id_pedido;
    END IF;
END$$

DELIMITER ;

-- Usar Stored Producers 
/* Agrego nuevo pedido para probar el SP */
INSERT INTO pedidos (id_cliente, fecha_entrega, total, estado_pago, estado_entrega) VALUES (1, '2025-09-06', 25000, "pendiente", "Pendiente");
CALL registrar_pago(4, 25000, 'Mercado Pago');

------------------
/* SP 2 */

DELIMITER $$

CREATE PROCEDURE actualizar_stock (
    IN p_id_pedido INT
)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_id_producto INT;
    DECLARE v_cantidad_producto DECIMAL(10,2);
    DECLARE v_comentario VARCHAR(100);

    -- Cursor para recorrer los productos del pedido, usamos la tabla intermedia detalles_pedido
    DECLARE cur_productos CURSOR FOR
        SELECT id_producto, cantidad, comentario
        FROM detalles_pedido
        WHERE id_pedido = p_id_pedido;

    /* Cuando el cursor llega al final de las filas, MySQL genera un error NOT FOUND.
    Este handler evita que eso detenga el SP.
    En lugar de error, pone done = 1 para indicar que no quedan más productos por recorrer. */
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Activa el cursor para empezar a recorrer las filas.
    OPEN cur_productos;

    /* FETCH cur_productos INTO ... → toma la siguiente fila del cursor y guarda los valores en las variables */
    -- leer_productos es el nombre del loop
    leer_productos: LOOP
        FETCH cur_productos INTO v_id_producto, v_cantidad_producto, v_comentario;
        IF done = 1 THEN
            LEAVE leer_productos;
        END IF;

        -- Resta todos los ingredientes del producto según receta
        UPDATE ingredientes i
        JOIN recetas r ON i.id_ingrediente = r.id_ingrediente
        SET i.stock_actual = i.stock_actual - (r.cantidad_usada * v_cantidad_producto)
        WHERE r.id_producto = v_id_producto;

        -- Si el comentario contiene "Oreos de decoracion", restar Oreos según receta
        IF v_comentario LIKE '%Oreos de decoracion%' THEN
            UPDATE ingredientes i
            JOIN recetas r ON i.id_ingrediente = r.id_ingrediente
            SET i.stock_actual = i.stock_actual - (r.cantidad_usada * v_cantidad_producto)
            WHERE r.id_producto = v_id_producto AND i.nombre = 'oreos';
        END IF;

        -- Si dice 'Sin Comentario', no hace nada
    END LOOP;

    CLOSE cur_productos;
END$$

DELIMITER ;

-- Usar Stored Producers 
/* Agrego el detalle pedido del nuevo pedido */
INSERT INTO detalles_pedido (id_pedido, id_producto, cantidad, precio_unitario, comentario) VALUES (4, 3, 1, 25000, "Oreos de decoracion"); 

/* Insertamos la receta del producto */
INSERT INTO recetas (id_producto, id_ingrediente, cantidad_usada, unidad_medida) VALUES (3, 7, 8, "unidad");
INSERT INTO recetas (id_producto, id_ingrediente, cantidad_usada, unidad_medida) VALUES (3, 2, 700, "gramos");
INSERT INTO recetas (id_producto, id_ingrediente, cantidad_usada, unidad_medida) VALUES (3, 3, 6, "unidad");
INSERT INTO recetas (id_producto, id_ingrediente, cantidad_usada, unidad_medida) VALUES (3, 4, 500, "mililitros");
CALL actualizar_stock(4);

-- Funciones
-- Creacion de Funciones
-- Funcion 1 
DELIMITER $$ 

CREATE FUNCTION stock_disponible_ingrediente(
    p_id_ingrediente INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_stock DECIMAL(10,2);

    -- Obtener stock del ingrediente
    SELECT stock_actual
    INTO v_stock
    FROM ingredientes
    WHERE id_ingrediente = p_id_ingrediente;

    RETURN v_stock;
END$$

DELIMITER ;

-- Usar Funcion
/* El as para que cuando muestre la query se muestre stock_oreo y no stock_disponible_ingrediente(7) */
SELECT stock_disponible_ingrediente(7) AS stock_oreo;

-- Creacion de Funciones
-- Funcion 2 
DELIMITER $$

/* Calculamos el total del pedido agregando las promociones */
CREATE FUNCTION calcular_total_pedido(
    p_id_pedido INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_descuento DECIMAL(10,2) DEFAULT 0;
    DECLARE v_tipo ENUM('Porcentaje', 'Monto Fijo');
    DECLARE v_valor DECIMAL(10,2);

    -- Calcular subtotal
    SELECT SUM(cantidad * precio_unitario)
    INTO v_total
    FROM detalles_pedido
    WHERE id_pedido = p_id_pedido;

    -- Verificar si hay promoción activa
    SELECT tipo, valor
    INTO v_tipo, v_valor
    FROM promociones
    WHERE CURDATE() >= fecha_inicio 
    AND (fecha_fin IS NULL OR CURDATE() <= fecha_fin)
    ORDER BY valor DESC
    LIMIT 1;
    /* si fecha fin es null la promo sigue vigente */

    -- Aplicar descuento si existe
    IF v_tipo = 'Porcentaje' THEN
        SET v_descuento = v_total * (v_valor / 100);
    ELSEIF v_tipo = 'Monto Fijo' THEN
        SET v_descuento = v_valor;
    END IF;

    -- Retornar total con descuento
    RETURN v_total - v_descuento;
END$$

DELIMITER ;

-- Usar Funcion
SELECT calcular_total_pedido(3) AS total_pedido; -- aca verificar si funca

-- Triggers
-- Creacion de Triggers
DELIMITER $$

-- Cuando se inserta un detalle
CREATE TRIGGER trg_detalles_pedido_insert
AFTER INSERT ON detalles_pedido
FOR EACH ROW
BEGIN
    UPDATE pedidos
    SET total = total + (NEW.cantidad * NEW.precio_unitario)
    WHERE id_pedido = NEW.id_pedido;
END$$

-- Cuando se actualiza un detalle (ej: cambia cantidad o precio)
CREATE TRIGGER trg_detalles_pedido_update
AFTER UPDATE ON detalles_pedido
FOR EACH ROW
BEGIN
    UPDATE pedidos
    SET total = total - (OLD.cantidad * OLD.precio_unitario) + (NEW.cantidad * NEW.precio_unitario)
    WHERE id_pedido = NEW.id_pedido;
END$$

-- Cuando se elimina un detalle
CREATE TRIGGER trg_detalles_pedido_delete
AFTER DELETE ON detalles_pedido
FOR EACH ROW
BEGIN
    UPDATE pedidos
    SET total = total - (OLD.cantidad * OLD.precio_unitario)
    WHERE id_pedido = OLD.id_pedido;
END$$

DELIMITER ;

-- Entrega final 

UPDATE pedidos SET estado_entrega = "Entregado"
WHERE id_pedido = 1;

UPDATE pedidos SET estado_entrega = "Entregado"
WHERE id_pedido = 2;

UPDATE pedidos SET estado_entrega = "Entregado"
WHERE id_pedido = 3;

UPDATE pedidos SET estado_entrega = "Entregado"
WHERE id_pedido = 4;