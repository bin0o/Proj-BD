---------------------------------------------------
-- CONSTRAINTS
---------------------------------------------------
-- Triggers

--1
DROP FUNCTION IF EXISTS chk_categoria_proc();

CREATE OR REPLACE FUNCTION chk_categoria_proc()
RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.categoria = NEW.super_categoria THEN
        Raise Exception 'Uma Categoria não pode estar contida em si própria';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS chk_categoria_trigger ON tem_outra;

CREATE TRIGGER chk_categoria_trigger
BEFORE INSERT ON tem_outra
FOR EACH ROW
EXECUTE PROCEDURE chk_categoria_proc();

--2

DROP FUNCTION IF EXISTS chk_unidades_reposicao_proc();

CREATE OR REPLACE FUNCTION chk_unidades_reposicao_proc()
RETURNS TRIGGER AS
$$
DECLARE unidades_planograma INT;
BEGIN
    SELECT unidades_plan INTO unidades_planograma
    FROM planograma WHERE
    ean = NEW.ean AND num_serie = NEW.num_serie AND fabricante = NEW.fabricante AND nro = NEW.nro;
    IF NEW.unidades_evento > unidades_planograma THEN
        RAISE EXCEPTION 'O número de unidades repostas num Evento de Reposição
        não pode exceder o número de unidades especificado no Planograma';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS chk_unidades_reposicao_trigger ON evento_reposicao;

CREATE TRIGGER chk_unidades_reposicao_trigger
BEFORE INSERT ON evento_reposicao
FOR EACH ROW
EXECUTE PROCEDURE chk_unidades_reposicao_proc();

--3

DROP FUNCTION IF EXISTS chk_produto_reposto_proc();

CREATE OR REPLACE FUNCTION chk_produto_reposto_proc()
RETURNS TRIGGER AS
$$
DECLARE nome_prateleira VARCHAR(80);
BEGIN
    
    SELECT nome 
    INTO nome_prateleira
    FROM prateleira NATURAL JOIN planograma
    WHERE NEW.ean = ean AND NEW.nro = nro AND NEW.num_serie = num_serie;
    
    IF nome_prateleira NOT IN (SELECT nome
    FROM tem_categoria
    WHERE NEW.ean = ean) THEN
        RAISE EXCEPTION 'Um Produto só pode ser reposto numa Prateleira
        que apresente (pelo menos) uma das Categorias desse produto';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS chk_produto_reposto_trigger ON evento_reposicao;

CREATE TRIGGER chk_produto_reposto_trigger
BEFORE INSERT ON evento_reposicao
FOR EACH ROW
EXECUTE PROCEDURE chk_produto_reposto_proc();
