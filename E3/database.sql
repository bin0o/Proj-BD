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
--- TABLES
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
     CONSTRAINT chk_tem_outra CHECK (super_categoria != categoria),
     CONSTRAINT pk_tem_outra PRIMARY KEY(categoria),
     CONSTRAINT fk_tem_outra_categoria FOREIGN KEY(categoria) REFERENCES categoria(nome),
     CONSTRAINT fk_tem_outra_super_categoria FOREIGN KEY(super_categoria) REFERENCES super_categoria(nome));

CREATE TABLE produto 
    (ean SERIAL NOT NULL,
     cat VARCHAR(80) NOT NULL,
     descr VARCHAR(200) NOT NULL,
     CONSTRAINT pk_produto PRIMARY KEY(ean),
     CONSTRAINT fk_produto_categoria FOREIGN KEY(cat) REFERENCES categoria(nome));

CREATE TABLE tem_categoria
    (ean SERIAL NOT NULL,
     nome VARCHAR(80) NOT NULL,
     CONSTRAINT pk_tem_categoria_produto PRIMARY KEY(ean,nome),
     CONSTRAINT fk_tem_categoria_produto FOREIGN KEY(ean) REFERENCES produto(ean),
     CONSTRAINT fk_tem_categoria_categoria FOREIGN KEY(nome) REFERENCES categoria(nome));

CREATE TABLE IVM 
    (num_serie SERIAL NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     CONSTRAINT pk_IVM PRIMARY KEY(num_serie,fabricante));

CREATE TABLE ponto_de_retalho
    (nome VARCHAR(50) NOT NULL,
     distrito VARCHAR(20) NOT NULL,
     concelho VARCHAR(20) NOT NULL,
     CONSTRAINT pk_ponto_de_retalho PRIMARY KEY(nome));

CREATE TABLE instalada_em
    (num_serie SERIAL NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     local_ VARCHAR(50) NOT NULL,
     CONSTRAINT pk_instalada_em PRIMARY KEY(num_serie, fabricante),
     CONSTRAINT fk_instalada_em_IVM FOREIGN KEY(num_serie, fabricante) REFERENCES IVM(num_serie, fabricante),
     CONSTRAINT fk_instalada_em_ponto_de_retalho FOREIGN KEY(local_) REFERENCES ponto_de_retalho(nome));

CREATE TABLE prateleira
    (nro INT NOT NULL,
     num_serie SERIAL NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     altura INT NOT NULL,
     nome VARCHAR(80) NOT NULL,
     CONSTRAINT pk_prateleira PRIMARY KEY(nro,num_serie, fabricante),
     CONSTRAINT fk_prateleira_IVM FOREIGN KEY(num_serie, fabricante) REFERENCES IVM(num_serie, fabricante),
     CONSTRAINT fk_prateleira_categoria FOREIGN KEY(nome) REFERENCES categoria(nome));

CREATE TABLE planograma
    (ean SERIAL NOT NULL,
     nro INT NOT NULL,
     num_serie SERIAL NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     faces INT NOT NULL,
     unidades INT NOT NULL, 
     loc VARCHAR(20) NOT NULL,
     CONSTRAINT pk_planograma PRIMARY KEY(ean, nro, num_serie, fabricante),
     CONSTRAINT fk_planorama_produto FOREIGN KEY(ean) REFERENCES produto(ean),
     CONSTRAINT fk_planograma_prateleira FOREIGN KEY(nro, num_serie, fabricante) REFERENCES prateleira(nro, num_serie, fabricante));

CREATE TABLE retalhista
    (tin INT NOT NULL,
     name_ VARCHAR(80) NOT NULL UNIQUE,
     CONSTRAINT pk_retalhista PRIMARY KEY(tin));

CREATE TABLE responsavel_por    
    (nome_cat VARCHAR(80) NOT NULL,
     tin INT NOT NULL,
     num_serie SERIAL NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     CONSTRAINT pk_responsavel_por PRIMARY KEY(num_serie, fabricante),
     CONSTRAINT fk_responsavel_for_IVM FOREIGN KEY(num_serie, fabricante) REFERENCES IVM(num_serie, fabricante),
     CONSTRAINT fk_responsavel_por_retalhista FOREIGN KEY(tin) REFERENCES retalhista(tin),
     CONSTRAINT fk_responsavel_por_categoria FOREIGN KEY(nome_cat) REFERENCES categoria(nome));

CREATE TABLE evento_reposicao
    (ean SERIAL NOT NULL,
     nro INT NOT NULL,
     num_serie SERIAL NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     instante TIMESTAMP NOT NULL,
     unidades INT NOT NULL,
     tin INT NOT NULL,
     CONSTRAINT pk_evento_reposicao PRIMARY KEY(ean, nro, num_serie, fabricante, instante),
     CONSTRAINT fk_evento_reposicao_planograma FOREIGN KEY(ean, nro, num_serie, fabricante) REFERENCES planograma(ean, nro, num_serie, fabricante),
     CONSTRAINT fk_evento_reposicao_retalhista FOREIGN KEY(tin) REFERENCES retalhista(tin));

/* manuel is a little bitch. my little bitch :) */
---------------------------------------------------
-- POPULATING
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
                            ('Sopas'),
                            ('Sopa Miso'),
                            ('Sopa de Cenoura'),
                            ('Sopa de Favas');

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
                                    ('Sopa Miso'),
                                    ('Sopa de Cenoura'),
                                    ('Sopa de Favas');

-- Super Categoria
INSERT INTO super_categoria VALUES 
                                    ('Barras'),
                                    ('Bebidas'),
                                    ('Sopas');

-- Tem Outra
INSERT INTO tem_outra VALUES 
                            ('Barras','Barras Energéticas'),
                            ('Barras','Barras de Frutas'),
                            ('Bebidas','Refrigerantes'),
                            ('Bebidas', 'Bebidas Alcoólicas'),
                            ('Bebidas', 'Bebidas Energéticas'),
                            ('Bebidas', 'Sumos de Fruta'),
                            ('Sopas', 'Sopa Miso'),
                            ('Sopas', 'Sopa de Cenoura'),
                            ('Sopas', 'Sopa de Favas');

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
                        ('150','Sopa Miso','Sopa Miso Simples'),
                        ('160','Sopa Miso','Sopa Miso com Cogumelos');

-- Tem Categoria
INSERT INTO tem_categoria VALUES
                                ('10','Barras Energéticas'),
                                ('20','Barras Energéticas'),
                                ('30','Barras de Frutas'),
                                ('40','Refrigerantes'),
                                ('50','Refrigerantes'),
                                ('60', 'Bebidas Alcoólicas'),
                                ('70','Barras Energéticas'),
                                ('80','Bebidas Energéticas'),
                                ('90','Sumos de Fruta'),
                                ('100','Sumos de Fruta'),
                                ('110','Fruta'),
                                ('120','Fruta'),
                                ('130','Legumes'),
                                ('140','Legumes'),
                                ('150','Sopa Miso'),
                                ('160','Sopa Miso');

-- IVM
INSERT INTO IVM VALUES 
                    ('1','Bosch'),
                    ('2','Rowenta'),
                    ('3','Bosch'),
                    ('4','Atlante'),
                    ('5','Cristallo');

-- Ponto de Retalho
INSERT INTO ponto_de_retalho VALUES 
                                    ('IST-Taguspark','Lisboa','Oeiras'),
                                    ('Repsol-Lisboa','Lisboa','Oriente'),
                                    ('Fórum-Castelo Branco','Castelo Branco','Castelo Branco');

-- Instalada Em
INSERT INTO instalada_em VALUES 
                                ('1','Bosch','Repsol-Lisboa'),
                                ('2','Rowenta','Fórum-Castelo Branco'),
                                ('3','Bosch','IST-Taguspark'),
                                ('4','Atlante','IST-Taguspark'),
                                ('5','Cristallo','Fórum-Castelo Branco');

-- Prateleira
INSERT INTO prateleira VALUES 
                                ('1','1','Bosch','15','Refrigerantes'),
                                ('2','3','Bosch','15','Barras Energéticas'),
                                ('1','4','Atlante','15','Sopas'),
                                ('2','4','Atlante','15','Fruta'),
                                ('3','5','Cristallo','15','Fruta'),
                                ('6','5','Cristallo','15','Bebidas Alcoólicas'),
                                ('5','2','Rowenta','15','Sumos de Fruta');

-- Planograma
INSERT INTO planograma VALUES 
                                ('60','1','1', 'Bosch','6','48','3'),
                                ('70','2','3', 'Bosch','6','48','5'),
                                ('120','3','5', 'Cristallo','5','40','5'),
                                ('80','2','4', 'Atlante','8','64','8'),
                                ('80','6','5', 'Cristallo','5','40','2'),
                                ('140','5','2', 'Rowenta','4','32','3');

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
                                    ('Barras Energéticas','968720710','3','Bosch'),
                                    ('Sumos de Fruta','968746229','2','Rowenta'),
                                    ('Fruta','208913249','5','Cristallo'),
                                    ('Sopas','496320710','4','Atlante');

-- Evento Reposição
INSERT INTO evento_reposicao VALUES ('60','1', '1','Bosch','18/02/2022','40','102415639'),
                                    ('120','3','5','Cristallo','21/05/2002','45','208913249');





---------------------------------------------------
-- CONSTRAINTS
---------------------------------------------------
--Triggers

CREATE FUNCTION chk_unidades_reposicao_proc()
RETURN VOID AS
$$
BEGIN
    IF NEW.unidades > planograma.unidades THEN
        RAISE EXCEPTION 'Unidades repostas não podem exceder as do planograma'
    END IF;
END;
$$ LANGUAGE sql;

CREATE TRIGGER chk_unidades_reposicao_trigger
BEFORE INSERT ON evento_reposicao
FOR EACH ROW EXECUTE PROCEDURE chk_unidades_reposicao_proc();
  
