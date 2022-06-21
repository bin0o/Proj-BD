DROP TABLE IF EXISTS categoria CASCADE;
DROP TABLE IF EXISTS categoria_simples CASCADE;
DROP TABLE IF EXISTS super_categoria CASCADE;
DROP TABLE IF EXISTS tem_outra CASCADE;
DROP TABLE IF EXISTS produto CASCADE;
DROP TABLE IF EXISTS tem_categoria CASCADE;
DROP TABLE IF EXISTS IVM CASCADE;
DROP TABLE IF EXISTS ponto_de_retalho CASCADE;
DROP TABLE IF EXISTS instalada_em CASCADE;
DROP TABLE IF EXISTS prateleira CASCADE;
DROP TABLE IF EXISTS planograma CASCADE;
DROP TABLE IF EXISTS retalhista CASCADE;
DROP TABLE IF EXISTS responsavel_por CASCADE;
DROP TABLE IF EXISTS evento_reposicao CASCADE;



---------------------------------------------------
--- TABLE CREATION
---------------------------------------------------

CREATE TABLE categoria
    (nome VARCHAR(80) NOT NULL,
     CONSTRAINT pk_categoria PRIMARY KEY(nome));

CREATE TABLE categoria_simples
    (nome VARCHAR(80) NOT NULL,
     CONSTRAINT pk_categoria_simples PRIMARY KEY(nome),
     CONSTRAINT fk_categoria_simples_categoria FOREIGN KEY(nome) REFERENCES categoria(nome));

CREATE TABLE super_categoria
    (nome VARCHAR(80) NOT NULL,
     CONSTRAINT pk_super_categoria PRIMARY KEY(nome),
     CONSTRAINT fk_super_categoria_categoria FOREIGN KEY(nome) REFERENCES categoria(nome));

CREATE TABLE tem_outra
    (super_categoria CHAR(20) NOT NULL,
     categoria CHAR(20) NOT NULL,
     CONSTRAINT pk_tem_outra PRIMARY KEY(categoria),
     CONSTRAINT fk_tem_outra_categoria FOREIGN KEY(categoria) REFERENCES categoria(nome),
     CONSTRAINT fk_tem_outra_super_categoria FOREIGN KEY(super_categoria) REFERENCES super_categoria(nome));

CREATE TABLE produto 
    (ean INT NOT NULL,
     cat VARCHAR(80) NOT NULL,
     descr VARCHAR(200) NOT NULL,
     CONSTRAINT pk_produto PRIMARY KEY(ean),
     CONSTRAINT fk_produto_categoria FOREIGN KEY(cat) REFERENCES categoria(nome));

CREATE TABLE tem_categoria
    (ean INT NOT NULL,
     nome VARCHAR(80) NOT NULL,
     CONSTRAINT pk_tem_categoria_produto PRIMARY KEY(ean,nome),
     CONSTRAINT fk_tem_categoria_produto FOREIGN KEY(ean) REFERENCES produto(ean),
     CONSTRAINT fk_tem_categoria_categoria FOREIGN KEY(nome) REFERENCES categoria(nome));

CREATE TABLE IVM 
    (num_serie INT NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     CONSTRAINT pk_IVM PRIMARY KEY(num_serie,fabricante));

CREATE TABLE ponto_de_retalho
    (nome VARCHAR(50) NOT NULL,
     distrito VARCHAR(20) NOT NULL,
     concelho VARCHAR(20) NOT NULL,
     CONSTRAINT pk_ponto_de_retalho PRIMARY KEY(nome));

CREATE TABLE instalada_em
    (num_serie INT NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     local_ VARCHAR(50) NOT NULL,
     CONSTRAINT pk_instalada_em PRIMARY KEY(num_serie, fabricante),
     CONSTRAINT fk_instalada_em_IVM FOREIGN KEY(num_serie, fabricante) REFERENCES IVM(num_serie, fabricante),
     CONSTRAINT fk_instalada_em_ponto_de_retalho FOREIGN KEY(local_) REFERENCES ponto_de_retalho(nome));

CREATE TABLE prateleira
    (nro INT NOT NULL,
     num_serie INT NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     altura INT NOT NULL,
     nome VARCHAR(80) NOT NULL,
     CONSTRAINT pk_prateleira PRIMARY KEY(nro,num_serie, fabricante),
     CONSTRAINT fk_prateleira_IVM FOREIGN KEY(num_serie, fabricante) REFERENCES IVM(num_serie, fabricante),
     CONSTRAINT fk_prateleira_categoria FOREIGN KEY(nome) REFERENCES categoria(nome));

CREATE TABLE planograma
    (ean INT NOT NULL,
     nro INT NOT NULL,
     num_serie INT NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     faces INT NOT NULL,
     unidades_plan INT NOT NULL, 
     loc VARCHAR(20) NOT NULL,
     CONSTRAINT pk_planograma PRIMARY KEY(ean, nro, num_serie, fabricante),
     CONSTRAINT fk_planograma_produto FOREIGN KEY(ean) REFERENCES produto(ean),
     CONSTRAINT fk_planograma_prateleira FOREIGN KEY(nro, num_serie, fabricante) REFERENCES prateleira(nro, num_serie, fabricante));

CREATE TABLE retalhista
    (tin INT NOT NULL,
     name_ VARCHAR(80) NOT NULL UNIQUE,
     CONSTRAINT pk_retalhista PRIMARY KEY(tin));

CREATE TABLE responsavel_por    
    (nome_cat VARCHAR(80) NOT NULL,
     tin INT NOT NULL,
     num_serie INT NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     CONSTRAINT pk_responsavel_por PRIMARY KEY(num_serie, fabricante),
     CONSTRAINT fk_responsavel_for_IVM FOREIGN KEY(num_serie, fabricante) REFERENCES IVM(num_serie, fabricante),
     CONSTRAINT fk_responsavel_por_retalhista FOREIGN KEY(tin) REFERENCES retalhista(tin),
     CONSTRAINT fk_responsavel_por_categoria FOREIGN KEY(nome_cat) REFERENCES categoria(nome));

CREATE TABLE evento_reposicao
    (ean INT NOT NULL,
     nro INT NOT NULL,
     num_serie INT NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     instante TIMESTAMP NOT NULL,
     unidades_evento INT NOT NULL,
     tin INT NOT NULL,
     CONSTRAINT pk_evento_reposicao PRIMARY KEY(ean, nro, num_serie, fabricante, instante),
     CONSTRAINT fk_evento_reposicao_planograma FOREIGN KEY(ean, nro, num_serie, fabricante) REFERENCES planograma(ean, nro, num_serie, fabricante),
     CONSTRAINT fk_evento_reposicao_retalhista FOREIGN KEY(tin) REFERENCES retalhista(tin));


---------------------------------------------------
-- CONSTRAINTS
---------------------------------------------------
--Triggers

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
DECLARE nome_categoria VARCHAR(80);
DECLARE nome_prateleira VARCHAR(80);
BEGIN
    SELECT nome
    INTO nome_categoria
    FROM tem_categoria
    WHERE NEW.ean = ean;

    SELECT nome 
    INTO nome_prateleira
    FROM prateleira NATURAL JOIN planograma
    WHERE NEW.ean = ean AND NEW.nro=nro AND NEW.num_serie=num_serie;
    
    IF nome_categoria != nome_prateleira THEN
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


/* manuel is a little bitch. my little bitch :) */
---------------------------------------------------
-- POPULATE RELATIONS
---------------------------------------------------
-- Categoria
INSERT INTO categoria VALUES 
                            ('Barras'),
                            ('Barras Energéticas'),
                            ('Barras de Frutas'),
                            ('Bebidas'),
                            ('Refrigerantes'),
                            ('Bebidas Alcoólicas'),
                            ('Bebidas Energéticas'),
                            ('Sumos de Fruta'),
                            ('Fruta'),
                            ('Legumes'),
                            ('Sopas');

-- Categoria Simples
INSERT INTO categoria_simples VALUES 
                                    ('Barras Energéticas'),
                                    ('Barras de Frutas'),
                                    ('Refrigerantes'),
                                    ('Bebidas Alcoólicas'),
                                    ('Bebidas Energéticas'),
                                    ('Sumos de Fruta'),
                                    ('Fruta'),
                                    ('Legumes'),
                                    ('Sopas');

-- Super Categoria
INSERT INTO super_categoria VALUES 
                                    ('Barras'),
                                    ('Bebidas');

-- Tem Outra
INSERT INTO tem_outra VALUES 
                            ('Barras','Barras Energéticas'),
                            ('Barras','Barras de Frutas'),
                            ('Bebidas','Refrigerantes'),
                            ('Bebidas', 'Bebidas Alcoólicas'),
                            ('Bebidas', 'Bebidas Energéticas'),
                            ('Bebidas', 'Sumos de Fruta');

-- Produto
INSERT INTO produto VALUES 
                        ('10','Barras Energéticas','Barra PB&J Prozis'),
                        ('20','Barras Energéticas','Barra Chocolate MyProtein'),
                        ('30','Barras de Frutas','Barra Maçã e Canela'),
                        ('40','Refrigerantes','Sumol'),
                        ('50','Refrigerantes','Coca-Cola'),
                        ('60','Bebidas Alcoólicas','Vodka'),
                        ('70','Bebidas Energéticas','Red Bull'),
                        ('80','Bebidas Energéticas','Monster'),
                        ('90','Sumos de Fruta','Sumo de Manga-Laranja'),
                        ('100','Sumos de Fruta','Sumo de Maçã'),
                        ('110','Fruta','Laranja'),
                        ('120','Fruta','Pêra'),
                        ('130','Legumes','Espinafre'),
                        ('140','Legumes','Cenoura'),
                        ('150','Sopas','Sopa Miso'),
                        ('160','Sopas','Sopa de Cenoura');

-- Tem Categoria
INSERT INTO tem_categoria VALUES
                                ('10','Barras Energéticas'),
                                ('20','Barras'),
                                ('30','Barras de Frutas'),
                                ('40','Refrigerantes'),
                                ('50','Refrigerantes'),
                                ('60', 'Bebidas Alcoólicas'),
                                ('70','Bebidas Energéticas'),
                                ('80','Bebidas Energéticas'),
                                ('90','Sumos de Fruta'),
                                ('100','Sumos de Fruta'),
                                ('110','Fruta'),
                                ('120','Fruta'),
                                ('130','Legumes'),
                                ('140','Legumes'),
                                ('150','Sopas'),
                                ('160','Sopas');

-- IVM
INSERT INTO IVM VALUES 
                    ('1','Bosch'),
                    ('2','Rowenta'),
                    ('3','Bosch'),
                    ('4','Atlante'),
                    ('5','Cristallo'),
                    ('6','Atlante'),
                    ('7', 'Cristallo'),
                    
                    ('8','IVM1'),
                    ('9','IVM2'),
                    ('10','IVM3'),
                    ('11','IVM4'),
                    ('12','IVM5'),
                    ('13','IVM6'),
                    ('14', 'IVM7'),
                    ('15', 'IVM8'),
                    ('16', 'IVM9'),
                    ('17', 'IVM10');

-- Ponto de Retalho
INSERT INTO ponto_de_retalho VALUES 
                                    ('IST-Taguspark','Lisboa','Oeiras'),
                                    ('Repsol-Lisboa','Lisboa','Oriente'),
                                    ('Fórum-Castelo Branco','Castelo Branco','Castelo Branco'),
                                    ('IST-Alameda','Lisboa','Lisboa');

-- Instalada Em
INSERT INTO instalada_em VALUES 
                                ('1','Bosch','Repsol-Lisboa'),
                                ('2','Rowenta','Fórum-Castelo Branco'),
                                ('3','Bosch','IST-Taguspark'),
                                ('4','Atlante','IST-Taguspark'),
                                ('5','Cristallo','Fórum-Castelo Branco'),
                                ('6','Atlante','Repsol-Lisboa'),
                                ('7','Cristallo','IST-Alameda'),
                                
                                ('8','IVM1','Repsol-Lisboa'),
                                ('9','IVM2','Repsol-Lisboa'),
                                ('10','IVM3','Repsol-Lisboa'),
                                ('11','IVM4','Repsol-Lisboa'),
                                ('12','IVM5','Repsol-Lisboa'),
                                ('13','IVM6','Repsol-Lisboa' ),
                                ('14', 'IVM7','Repsol-Lisboa' ),
                                ('15', 'IVM8','Repsol-Lisboa' ),
                                ('16', 'IVM9','Repsol-Lisboa' ),
                                ('17','IVM10','Repsol-Lisboa');

-- Prateleira
INSERT INTO prateleira VALUES 
                                ('1','1','Bosch','15','Refrigerantes'),
                                ('2','3','Bosch','15','Barras Energéticas'),
                                ('1','4','Atlante','15','Sopas'),
                                ('2','4','Atlante','15','Refrigerantes'),
                                ('3','5','Cristallo','15','Fruta'),
                                ('6','5','Cristallo','15','Bebidas Energéticas'),
                                ('5','2','Rowenta','15','Sumos de Fruta'),
                                ('5','7','Cristallo','15','Bebidas Energéticas'),

                                ('1','8','IVM1','15','Barras Energéticas'),
                                ('1','9','IVM2','15','Barras de Frutas'),
                                ('1','10','IVM3','15','Refrigerantes'),
                                ('1','11','IVM4','15','Bebidas Alcoólicas'),
                                ('1','12','IVM5','15','Bebidas Energéticas'),
                                ('1','13','IVM6','15','Sumos de Fruta'),
                                ('1','14','IVM7','15','Fruta'),
                                ('1','15','IVM8','15','Legumes'),
                                ('1','16','IVM9','15','Sopas'),
                                ('1','17','IVM10','15','Barras');

-- Planograma
INSERT INTO planograma VALUES 
                                ('50','1','1', 'Bosch','6','48','3'),
                                ('70','2','3', 'Bosch','6','48','5'),
                                ('120','3','5', 'Cristallo','5','40','5'),
                                ('50','2','4', 'Atlante','8','64','8'),
                                ('80','6','5', 'Cristallo','5','40','2'),
                                ('140','5','2', 'Rowenta','4','32','3'),
                                ('80','5','7', 'Cristallo','5','40','2'),

                                ('10','1','8','IVM1','6','48','3'),
                                ('30','1','9','IVM2','6','48','3'),
                                ('50','1','10','IVM3','6','48','3'),
                                ('60','1','11','IVM4','6','48','3'),
                                ('80','1','12','IVM5','6','48','3'),
                                ('100','1','13','IVM6','6','48','3'),
                                ('120','1','14','IVM7','6','48','3'),
                                ('140','1','15','IVM8','6','48','3'),
                                ('160','1','16','IVM9','6','48','3'),
                                ('20','1','17','IVM10','6','48','3');

-- Retalhista
INSERT INTO retalhista VALUES
                                ('102415639','Auchan'),
                                ('968746229','Recheio'),
                                ('208913249','Lidl'),
                                ('496320710','Intermarché'),
                                ('968720710','Pingo Doce'),
                                ('496326229','Jumbo');

-- Responsável Por
INSERT INTO responsavel_por VALUES 
                                    ('Refrigerantes','102415639','1','Bosch'),
                                    ('Barras Energéticas','102415639','3','Bosch'),
                                    ('Sumos de Fruta','968746229','2','Rowenta'),
                                    ('Fruta','208913249','5','Cristallo'),
                                    ('Refrigerantes','496320710','4','Atlante'),
                                    ('Refrigerantes','496320710','6','Atlante'),
                                    ('Bebidas Energéticas','496326229','7','Cristallo'),

                                    ('Barras Energéticas','968720710','8','IVM1'),
                                    ('Barras de Frutas','968720710','9','IVM2'),
                                    ('Refrigerantes','968720710','10','IVM3'),
                                    ('Bebidas Alcoólicas','968720710','11','IVM4'),
                                    ('Bebidas Energéticas','968720710','12','IVM5'),
                                    ('Sumos de Fruta','968720710','13','IVM6'),
                                    ('Fruta','968720710','14','IVM7'),
                                    ('Legumes','968720710','15','IVM8'),
                                    ('Sopas','968720710','16','IVM9'),
                                    ('Barras','968720710','17','IVM10');

-- Evento Reposição
INSERT INTO evento_reposicao VALUES ('50','1', '1','Bosch','18/02/2022','10','102415639'),
                                    ('120','3','5','Cristallo','21/05/2022','15','208913249'),
                                    ('50','2','4','Atlante', '26/09/2022','20','496320710'),
                                    ('50','1', '1','Bosch','18/02/2023','25','102415639'),
                                    ('120','3','5','Cristallo','22/05/2022','30','208913249'),
                                    ('80','5','7', 'Cristallo', '20/06/2022', '35', '496326229');




--------------------------------------------------
-- SQL
--------------------------------------------------
/*
--- 1.

SELECT name_ 
FROM retalhista NATURAL JOIN responsavel_por 
GROUP BY tin
HAVING COUNT(nome_cat) >= ALL(
SELECT COUNT(nome_cat) 
FROM retalhista NATURAL JOIN responsavel_por
GROUP BY tin);


--- 2.


SELECT name_ 
FROM retalhista NATURAL JOIN responsavel_por RIGHT JOIN categoria_simples 
ON nome_cat=nome 
GROUP BY tin 
HAVING (SELECT COUNT(*) FROM categoria_simples)=COUNT(nome_cat);


--- 3.

SELECT produto.ean 
FROM evento_reposicao RIGHT JOIN produto 
ON produto.ean = evento_reposicao.ean 
GROUP BY produto.ean 
HAVING COUNT(evento_reposicao.ean) = 0;

--- 4.
SELECT ean 
FROM (SELECT DISTINCT ean, tin FROM evento_reposicao) AS count_ean
GROUP BY ean 
HAVING COUNT(ean) = 1;
*/
--------------------------------------------------
CREATE OR REPLACE VIEW vendas AS
SELECT ean,
    cat.nome AS cat, 
    EXTRACT(YEAR FROM instante) AS ano, 
    EXTRACT(QUARTER FROM instante) AS trimestre, 
    EXTRACT(MONTH FROM instante) AS mes,
    EXTRACT(DAY FROM instante) AS dia_mes, 
    CASE EXTRACT(DOW FROM instante)
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Segunda'
        WHEN 2 THEN 'Terça'
        WHEN 3 THEN 'Quarta'
        WHEN 4 THEN 'Quinta'
        WHEN 5 THEN 'Sexta'
        WHEN 6 THEN 'Sábado'
    END AS dia_semana, 
    distrito, 
    concelho, 
    unidades_evento AS unidades 
    FROM tem_categoria AS cat NATURAL JOIN evento_reposicao
        NATURAL JOIN instalada_em  
        JOIN ponto_de_retalho ON local_ = ponto_de_retalho.nome;


---------------------------------------------
--OLAP
---------------------------------------------
--1
-- SELECT  dia_semana, concelho, SUM(unidades) 
-- FROM vendas 
-- WHERE (ano > 2022 OR (ano = 2022  AND ( mes > 5 OR  ( mes=5 AND (dia_mes >= 21))))) 
-- AND (ano<2023 OR (ano=2023 AND (mes < 2 OR (mes = 2 AND (dia_mes <=18))))) 
-- GROUP BY CUBE(dia_semana,concelho) ORDER BY(dia_semana,concelho);
--2
-- SELECT concelho, cat, dia_semana, SUM(unidades)
-- FROM vendas
-- WHERE distrito = 'Lisboa'
-- GROUP BY CUBE(concelho,cat,dia_semana)
-- ORDER BY(concelho, cat, dia_semana);
-- 2.1
-- SELECT concelho, cat, dia_semana, SUM(unidades)
-- FROM vendas
-- WHERE distrito = 'Lisboa'
-- GROUP BY GROUPING SETS((concelho),(cat),(dia_semana),())
-- ORDER BY(concelho, cat, dia_semana);
