CREATE OR REPLACE FUNCTION soporte.fn_descontar_stock_inventario()
RETURNS TRIGGER AS $$
BEGIN
    -- Update stock
    UPDATE soporte.inventario
    SET stock_actual = stock_actual - NEW.cantidad
    WHERE id_item_inventario = NEW.id_item_inventario;

    -- Validation
    IF (SELECT stock_actual FROM soporte.inventario WHERE id_item_inventario = NEW.id_item_inventario) < 0 THEN
        RAISE EXCEPTION 'Stock insuficiente para el ítem ID %', NEW.id_item_inventario;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_descontar_stock_inventario ON soporte.inventario_usado_ticket;
CREATE TRIGGER trg_descontar_stock_inventario
AFTER INSERT ON soporte.inventario_usado_ticket
FOR EACH ROW
EXECUTE FUNCTION soporte.fn_descontar_stock_inventario();
