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

DROP INDEX IF EXISTS tin_responsavel_por_idx;
DROP INDEX IF EXISTS cat_responsavel_por_idx;
DROP INDEX IF EXISTS produto_idx;


---------------------------------------------------
--- TABLE CREATION
---------------------------------------------------

CREATE TABLE categoria
    (nome VARCHAR(80) NOT NULL,
     CONSTRAINT pk_categoria PRIMARY KEY(nome));

CREATE TABLE categoria_simples
    (nome VARCHAR(80) NOT NULL,
     CONSTRAINT pk_categoria_simples PRIMARY KEY(nome),
     CONSTRAINT fk_categoria_simples_categoria FOREIGN KEY(nome) REFERENCES categoria(nome) ON DELETE CASCADE);

CREATE TABLE super_categoria
    (nome VARCHAR(80) NOT NULL,
     CONSTRAINT pk_super_categoria PRIMARY KEY(nome),
     CONSTRAINT fk_super_categoria_categoria FOREIGN KEY(nome) REFERENCES categoria(nome) ON DELETE CASCADE);

CREATE TABLE tem_outra
    (super_categoria CHAR(80) NOT NULL,
     categoria CHAR(80) NOT NULL,
     CONSTRAINT pk_tem_outra PRIMARY KEY(categoria),
     CONSTRAINT fk_tem_outra_categoria FOREIGN KEY(categoria) REFERENCES categoria(nome) ON DELETE CASCADE,
     CONSTRAINT fk_tem_outra_super_categoria FOREIGN KEY(super_categoria) REFERENCES super_categoria(nome) ON DELETE CASCADE);

CREATE TABLE produto 
    (ean INT NOT NULL,
     cat VARCHAR(80) NOT NULL,
     descr VARCHAR(200) NOT NULL,
     CONSTRAINT pk_produto PRIMARY KEY(ean),
     CONSTRAINT fk_produto_categoria FOREIGN KEY(cat) REFERENCES categoria(nome) ON DELETE CASCADE);

CREATE TABLE tem_categoria
    (ean INT NOT NULL,
     nome VARCHAR(80) NOT NULL,
     CONSTRAINT pk_tem_categoria_produto PRIMARY KEY(ean,nome),
     CONSTRAINT fk_tem_categoria_produto FOREIGN KEY(ean) REFERENCES produto(ean),
     CONSTRAINT fk_tem_categoria_categoria FOREIGN KEY(nome) REFERENCES categoria(nome) ON DELETE CASCADE);

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
     CONSTRAINT fk_prateleira_categoria FOREIGN KEY(nome) REFERENCES categoria(nome) ON DELETE CASCADE);

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
     CONSTRAINT fk_responsavel_por_retalhista FOREIGN KEY(tin) REFERENCES retalhista(tin) ON DELETE CASCADE,
     CONSTRAINT fk_responsavel_por_categoria FOREIGN KEY(nome_cat) REFERENCES categoria(nome) ON DELETE CASCADE);

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
     CONSTRAINT fk_evento_reposicao_retalhista FOREIGN KEY(tin) REFERENCES retalhista(tin) ON DELETE CASCADE);


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

---------------------------------------------------
-- POPULATE RELATIONS
---------------------------------------------------
-- Categoria
INSERT INTO categoria VALUES 
                            ('Biológicos'),
                            ('Cereais e Barras'),
                            ('Barras'),
                            ('Barras Energéticas'),
                            ('Barras de Frutas'),
                            ('Bebidas e Garrafeira'),
                            ('Refrigerantes'),
                            ('Garrafeira'),
                            ('Bebidas Espirituosas'),
                            ('Bebidas Energéticas'),
                            ('Sumos de Frutas'),
                            ('Sopas'),
                            ('Produtos Frescos'),
                            ('Frutas'),
                            ('Legumes'),
                            ('Padaria e Pastelaria'),
                            ('Pão'),
                            ('Pão Caseiro'),
                            ('Pão Caseiro Sementes'),
                            ('Pão Caseiro Simples'),
                            ('Pão de Forma'),
                            ('Pão de Forma Sementes'),
                            ('Pão de Forma Simples');

-- Categoria Simples
INSERT INTO categoria_simples VALUES 
                                    ('Barras Energéticas'),
                                    ('Barras de Frutas'),
                                    ('Refrigerantes'),
                                    ('Bebidas Espirituosas'),
                                    ('Bebidas Energéticas'),
                                    ('Sumos de Frutas'),
                                    ('Frutas'),
                                    ('Legumes'),
                                    ('Sopas'),
                                    ('Pão Caseiro Sementes'),
                                    ('Pão Caseiro Simples'),
                                    ('Pão de Forma Sementes'),
                                    ('Pão de Forma Simples');

-- Super Categoria
INSERT INTO super_categoria VALUES 
                                    ('Biológicos'),
                                    ('Cereais e Barras'),
                                    ('Barras'),
                                    ('Bebidas e Garrafeira'),
                                    ('Garrafeira'),
                                    ('Produtos Frescos'),
                                    ('Padaria e Pastelaria'),
                                    ('Pão'),
                                    ('Pão Caseiro'),
                                    ('Pão de Forma');

-- Tem Outra
INSERT INTO tem_outra VALUES 
                            ('Biológicos', 'Cereais e Barras'),
                            ('Cereais e Barras', 'Barras'),
                            ('Barras','Barras Energéticas'),
                            ('Barras','Barras de Frutas'),
                            ('Bebidas e Garrafeira','Refrigerantes'),
                            ('Bebidas e Garrafeira', 'Garrafeira'),
                            ('Garrafeira', 'Bebidas Espirituosas'),
                            ('Bebidas e Garrafeira', 'Bebidas Energéticas'),
                            ('Bebidas e Garrafeira', 'Sumos de Frutas'),
                            ('Produtos Frescos', 'Frutas'),
                            ('Produtos Frescos', 'Legumes'),
                            ('Produtos Frescos', 'Padaria e Pastelaria'),
                            ('Padaria e Pastelaria', 'Pão'),
                            ('Pão', 'Pão Caseiro'),
                            ('Pão', 'Pão de Forma'),
                            ('Pão Caseiro', 'Pão Caseiro Sementes'),
                            ('Pão Caseiro', 'Pão Caseiro Simples'),
                            ('Pão de Forma', 'Pão de Forma Sementes'),
                            ('Pão de Forma', 'Pão de Forma Simples');

-- Produto
INSERT INTO produto VALUES 
                        ('10','Barras Energéticas','Barra PB&J Prozis'),
                        ('20','Barras Energéticas','Barra Chocolate MyProtein'),
                        ('30','Barras Energéticas','Barra Fitness Mel e Amêndoas'),
                        ('40','Barras Energéticas','Barra Cereais Aveia'),
                        ('50','Barras de Frutas','Barra Maçã e Canela'),
                        ('60','Barras de Frutas','Barra Chocolate e Morango'),
                        ('70','Barras de Frutas','Barra Muesli e Côco'),
                        ('80','Barras de Frutas','Barra Iogurte e Alperce'),
                        ('90','Refrigerantes','Sumol'),
                        ('100','Refrigerantes','Coca-Cola'),
                        ('110','Refrigerantes','Ice Tea'),
                        ('120','Refrigerantes','Guaraná'),
                        ('130','Bebidas Espirituosas','Vodka'),
                        ('140','Bebidas Espirituosas','Gin'),
                        ('150','Bebidas Espirituosas','Tequila'),
                        ('160','Bebidas Energéticas','Red Bull'),
                        ('170','Bebidas Energéticas','Monster'),
                        ('180','Sumos de Frutas','Sumo de Manga-Laranja'),
                        ('190','Sumos de Frutas','Sumo de Maçã'),
                        ('200','Sumos de Frutas','Sumo de Tutti Frutti'),
                        ('210','Sumos de Frutas','Sumo de Frutos Vermelhos'),
                        ('220','Sumos de Frutas','Sumo de Maracujá'),
                        ('230','Frutas','Laranja'),
                        ('240','Frutas','Pêra'),
                        ('250','Frutas','Banana'),
                        ('260','Frutas','Maçã'),
                        ('270','Legumes','Espinafre'),
                        ('280','Legumes','Cenoura'),
                        ('290','Legumes','Bróculos'),
                        ('300','Legumes','Courgete'),
                        ('310','Sopas','Sopa Miso'),
                        ('320','Sopas','Sopa de Cenoura'),
                        ('330','Sopas','Sopa de Alho Francês'),
                        ('340','Sopas','Sopa da Pedra'),
                        ('350','Pão Caseiro Sementes','Pão Prokorn'),
                        ('360','Pão Caseiro Sementes','Pão com Passas'),
                        ('370','Pão Caseiro Sementes','Chapata de Cereais'),
                        ('380','Pão Caseiro Simples','Pão Vianinha'),
                        ('390','Pão Caseiro Simples','Carcaça Portuguesa'),
                        ('400','Pão Caseiro Simples','Pão de Alfarroba'),
                        ('410','Pão Caseiro Simples','Pão Alentejano'),
                        ('420','Pão de Forma Sementes','Pão de Centeio'),
                        ('430','Pão de Forma Sementes','Pão de 9 Cereais s/ côdea'),
                        ('440','Pão de Forma Sementes','Pão Integral com Sementes'),
                        ('450','Pão de Forma Simples','Pão Especial Torradas'),
                        ('460','Pão de Forma Simples','Pão Artesanal'),
                        ('470','Pão de Forma Simples','Bagels');

-- Tem Categoria
INSERT INTO tem_categoria VALUES
                                ('10','Biológicos'),
                                ('10','Cereais e Barras'),
                                ('10','Barras'),
                                ('10','Barras Energéticas'),
                                ('20','Biológicos'),
                                ('20','Cereais e Barras'),
                                ('20','Barras'),
                                ('20','Barras Energéticas'),
                                ('30','Biológicos'),
                                ('30','Cereais e Barras'),
                                ('30','Barras'),
                                ('30','Barras Energéticas'),
                                ('40','Biológicos'),
                                ('40','Cereais e Barras'),
                                ('40','Barras'),
                                ('40','Barras Energéticas'),
                                ('50','Biológicos'),
                                ('50','Cereais e Barras'),
                                ('50','Barras'),
                                ('50','Barras de Frutas'),
                                ('60','Biológicos'),
                                ('60','Cereais e Barras'),
                                ('60','Barras'),
                                ('60','Barras de Frutas'),
                                ('70','Biológicos'),
                                ('70','Cereais e Barras'),
                                ('70','Barras'),
                                ('70','Barras de Frutas'),
                                ('80','Biológicos'),
                                ('80','Cereais e Barras'),
                                ('80','Barras'),
                                ('80','Barras de Frutas'),
                                ('90', 'Bebidas e Garrafeira'),
                                ('90','Refrigerantes'),
                                ('100', 'Bebidas e Garrafeira'),
                                ('100','Refrigerantes'),
                                ('110', 'Bebidas e Garrafeira'),
                                ('110','Refrigerantes'),
                                ('120', 'Bebidas e Garrafeira'),
                                ('120','Refrigerantes'),
                                ('130', 'Bebidas e Garrafeira'),
                                ('130', 'Garrafeira'),
                                ('130', 'Bebidas Espirituosas'),
                                ('140', 'Bebidas e Garrafeira'),
                                ('140', 'Garrafeira'),
                                ('140', 'Bebidas Espirituosas'),
                                ('150', 'Bebidas e Garrafeira'),
                                ('150', 'Garrafeira'),
                                ('150', 'Bebidas Espirituosas'),
                                ('160', 'Bebidas e Garrafeira'),
                                ('160','Bebidas Energéticas'),
                                ('170', 'Bebidas e Garrafeira'),
                                ('170','Bebidas Energéticas'),
                                ('180', 'Bebidas e Garrafeira'),
                                ('180','Sumos de Frutas'),
                                ('190', 'Bebidas e Garrafeira'),
                                ('190','Sumos de Frutas'),
                                ('200', 'Bebidas e Garrafeira'),
                                ('200','Sumos de Frutas'),
                                ('210', 'Bebidas e Garrafeira'),
                                ('210','Sumos de Frutas'),
                                ('220', 'Bebidas e Garrafeira'),
                                ('220','Sumos de Frutas'),
                                ('230', 'Produtos Frescos'),
                                ('230','Frutas'),
                                ('240', 'Produtos Frescos'),
                                ('240','Frutas'),
                                ('250', 'Produtos Frescos'),
                                ('250','Frutas'),
                                ('260', 'Produtos Frescos'),
                                ('260','Frutas'),
                                ('270', 'Produtos Frescos'),
                                ('270','Legumes'),
                                ('280', 'Produtos Frescos'),
                                ('280','Legumes'),
                                ('290', 'Produtos Frescos'),
                                ('290','Legumes'),
                                ('300', 'Produtos Frescos'),
                                ('300','Legumes'),
                                ('310','Sopas'),
                                ('320','Sopas'),
                                ('330','Sopas'),
                                ('340','Sopas'),
                                ('350', 'Produtos Frescos'),
                                ('350', 'Padaria e Pastelaria'),
                                ('350', 'Pão'),
                                ('350', 'Pão Caseiro'),
                                ('350','Pão Caseiro Sementes'),
                                ('360', 'Produtos Frescos'),
                                ('360', 'Padaria e Pastelaria'),
                                ('360', 'Pão'),
                                ('360', 'Pão Caseiro'),
                                ('360','Pão Caseiro Sementes'),
                                ('370', 'Produtos Frescos'),
                                ('370', 'Padaria e Pastelaria'),
                                ('370', 'Pão'),
                                ('370', 'Pão Caseiro'),
                                ('370','Pão Caseiro Sementes'),
                                ('380', 'Produtos Frescos'),
                                ('380', 'Padaria e Pastelaria'),
                                ('380', 'Pão'),
                                ('380', 'Pão Caseiro'),
                                ('380','Pão Caseiro Simples'),
                                ('390', 'Produtos Frescos'),
                                ('390', 'Padaria e Pastelaria'),
                                ('390', 'Pão'),
                                ('390', 'Pão Caseiro'),
                                ('390','Pão Caseiro Simples'),
                                ('400', 'Produtos Frescos'),
                                ('400', 'Padaria e Pastelaria'),
                                ('400', 'Pão'),
                                ('400', 'Pão Caseiro'),
                                ('400','Pão Caseiro Simples'),
                                ('410', 'Produtos Frescos'),
                                ('410', 'Padaria e Pastelaria'),
                                ('410', 'Pão'),
                                ('410', 'Pão Caseiro'),
                                ('410','Pão Caseiro Simples'),
                                ('420', 'Produtos Frescos'),
                                ('420', 'Padaria e Pastelaria'),
                                ('420', 'Pão'),
                                ('420', 'Pão de Forma'),
                                ('420','Pão de Forma Sementes'),
                                ('430', 'Produtos Frescos'),
                                ('430', 'Padaria e Pastelaria'),
                                ('430', 'Pão'),
                                ('430', 'Pão de Forma'),
                                ('430','Pão de Forma Sementes'),
                                ('440', 'Produtos Frescos'),
                                ('440', 'Padaria e Pastelaria'),
                                ('440', 'Pão'),
                                ('440', 'Pão de Forma'),
                                ('440','Pão de Forma Sementes'),
                                ('450', 'Produtos Frescos'),
                                ('450', 'Padaria e Pastelaria'),
                                ('450', 'Pão'),
                                ('450', 'Pão de Forma'),
                                ('450','Pão de Forma Simples'),
                                ('460', 'Produtos Frescos'),
                                ('460', 'Padaria e Pastelaria'),
                                ('460', 'Pão'),
                                ('460', 'Pão de Forma'),
                                ('460','Pão de Forma Simples'),
                                ('470', 'Produtos Frescos'),
                                ('470', 'Padaria e Pastelaria'),
                                ('470', 'Pão'),
                                ('470', 'Pão de Forma'),
                                ('470','Pão de Forma Simples');

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
                    ('17', 'IVM10'),
                    ('18', 'Bosch'),
                    ('19','IVM11'),
                    ('20','IVM12'),
                    ('21','IVM13'),
                    ('22','IVM14');

-- Ponto de Retalho
INSERT INTO ponto_de_retalho VALUES 
                                    ('IST-Taguspark','Lisboa','Oeiras'),
                                    ('IST-Alameda','Lisboa','Lisboa'),
                                    ('Repsol-Lisboa','Lisboa','Oriente'),
                                    ('Fórum-Castelo Branco','Castelo Branco','Castelo Branco');
                                
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
                                ('9','IVM2','Fórum-Castelo Branco'),
                                ('10','IVM3','Repsol-Lisboa'),
                                ('11','IVM4','IST-Taguspark'),
                                ('12','IVM5','Repsol-Lisboa'),
                                ('13','IVM6','IST-Alameda' ),
                                ('14', 'IVM7','Repsol-Lisboa' ),
                                ('15', 'IVM8','IST-Taguspark' ),
                                ('16', 'IVM9','Repsol-Lisboa' ),
                                ('17','IVM10','Repsol-Lisboa'),
                                ('18','Bosch','Fórum-Castelo Branco'),
                                ('19','IVM11','Repsol-Lisboa'),
                                ('20','IVM12','IST-Alameda'),
                                ('21','IVM13','Repsol-Lisboa'),
                                ('22','IVM14','Fórum-Castelo Branco');

-- Prateleira
INSERT INTO prateleira VALUES 
                                ('1','1','Bosch','15','Barras'),
                                ('2','1','Bosch','15','Biológicos'),
                                ('5','2','Rowenta','15','Barras de Frutas'),
                                ('2','2','Rowenta','15','Sopas'),
                                ('2','3','Bosch','15','Bebidas e Garrafeira'),
                                ('6','3','Bosch','15','Frutas'),
                                ('1','4','Atlante','15','Sopas'),
                                ('2','4','Atlante','15','Refrigerantes'),
                                ('3','5','Cristallo','15','Frutas'),
                                ('6','5','Cristallo','15','Bebidas Energéticas'),
                                ('1', '6', 'Atlante', '15', 'Pão'),
                                ('5','7','Cristallo','15','Bebidas Energéticas'),
                                ('1','8','IVM1','15','Barras Energéticas'),
                                ('1','9','IVM2','15','Barras de Frutas'),
                                ('1','10','IVM3','15','Refrigerantes'),
                                ('1','11','IVM4','15','Bebidas Espirituosas'),
                                ('1','12','IVM5','15','Bebidas Energéticas'),
                                ('1','13','IVM6','15','Sumos de Frutas'),
                                ('1','14','IVM7','15','Frutas'),
                                ('1','15','IVM8','15','Legumes'),
                                ('1','16','IVM9','15','Sopas'),
                                ('1','17','IVM10','15','Barras'),
                                ('1','18','Bosch','15','Frutas'),
                                ('1','19','IVM11','15','Pão Caseiro Sementes'),
                                ('1','20','IVM12','15','Pão Caseiro Simples'),
                                ('1','21','IVM13','15','Pão de Forma Sementes'),
                                ('1','22','IVM14','15','Pão de Forma Simples');

-- Planograma
INSERT INTO planograma VALUES 
                                ('10','1','1', 'Bosch','6','48','3'),
                                ('50','1','1', 'Bosch','6','48','3'),
                                ('80','1','1', 'Bosch','6','48','3'),
                                ('40','2','1', 'Bosch','6','48','3'),
                                ('50', '5', '2', 'Rowenta', '4', '24', '3'),
                                ('310', '2', '2', 'Rowenta', '2', '12', '3'),
                                ('220','2','3', 'Bosch','4','32','5'),
                                ('160','2','3', 'Bosch','4','32','5'),
                                ('130','2','3', 'Bosch','4','32','5'),
                                ('250','6','3', 'Bosch','6','36','5'),
                                ('340','1','4', 'Atlante','8','64','8'),
                                ('330','1','4', 'Atlante','8','64','8'),
                                ('90', '2', '4', 'Atlante', '4', '16', '8'),
                                ('240','3','5', 'Cristallo','5','40','5'),
                                ('170','6','5', 'Cristallo','5','40','2'),
                                ('380', '1', '6', 'Atlante', '3', '36', '5'),
                                ('440', '1', '6', 'Atlante', '3', '36', '5'),
                                ('410', '1', '6', 'Atlante', '3', '36', '5'),
                                ('470', '1', '6', 'Atlante', '3', '36', '5'),
                                ('170','5','7', 'Cristallo','5','40','2'),
                                ('30','1','8','IVM1','6','48','3'),
                                ('80','1','9','IVM2','6','48','3'),
                                ('120','1','10','IVM3','6','48','3'),
                                ('150','1','11','IVM4','6','48','3'),
                                ('170','1','12','IVM5','6','48','3'),
                                ('200','1','13','IVM6','6','48','3'),
                                ('230','1','14','IVM7','6','48','3'),
                                ('300','1','15','IVM8','6','48','3'),
                                ('340','1','16','IVM9','6','48','3'),
                                ('20','1','17','IVM10','6','48','3'),
                                ('230','1','18','Bosch','6','48','3'),
                                ('350','1','19','IVM11','6','48','3'),
                                ('400','1','20','IVM12','6','48','3'),
                                ('440','1','21','IVM13','6','48','3'),
                                ('470','1','22','IVM14','6','48','3');

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
                                    ('Barras','102415639','1','Bosch'),
                                    ('Barras de Frutas','968746229','2','Rowenta'),
                                    ('Bebidas e Garrafeira','102415639','3','Bosch'),
                                    ('Sopas','496320710','4','Atlante'),
                                    ('Frutas','208913249','5','Cristallo'),
                                    ('Pão','496320710','6','Atlante'),
                                    ('Bebidas Energéticas', '208913249', '7', 'Cristallo'),
                                    ('Barras Energéticas','968720710','8','IVM1'),
                                    ('Barras de Frutas','968720710','9','IVM2'),
                                    ('Refrigerantes','968720710','10','IVM3'),
                                    ('Bebidas Espirituosas','968720710','11','IVM4'),
                                    ('Bebidas Energéticas','968720710','12','IVM5'),
                                    ('Sumos de Frutas','968720710','13','IVM6'),
                                    ('Frutas','968720710','14','IVM7'),
                                    ('Legumes','968720710','15','IVM8'),
                                    ('Sopas','968720710','16','IVM9'),
                                    ('Barras','968720710','17','IVM10'),
                                    ('Frutas', '208913249', '18', 'Bosch'),
                                    ('Pão Caseiro Sementes','968720710','19','IVM11'),
                                    ('Pão Caseiro Simples','968720710','20','IVM12'),
                                    ('Pão de Forma Sementes','968720710','21','IVM13'),
                                    ('Pão de Forma Simples','968720710','22','IVM14');

-- Evento Reposição
INSERT INTO evento_reposicao VALUES ('10','1', '1','Bosch','18/02/2022','10','102415639'),
                                    ('80','1', '1','Bosch','18/02/2022','10','102415639'),
                                    ('50', '5', '2', 'Rowenta', '24/06/2022', '20', '968746229'),
                                    ('220', '2', '3', 'Bosch', '26/05/2022', '32', '102415639'),
                                    ('160', '2', '3', 'Bosch', '26/05/2022', '30', '102415639'),
                                    ('130', '2', '3', 'Bosch', '26/05/2022', '30', '102415639'),
                                    ('340', '1', '4', 'Atlante', '30/04/2022', '40', '496320710'),
                                    ('330', '1', '4', 'Atlante', '30/04/2022', '45', '496320710'),
                                    ('240','3','5','Cristallo','21/05/2022','15','208913249'),
                                    ('380', '1', '6', 'Atlante', '1/02/2022', '20', '496320710'),
                                    ('440', '1', '6', 'Atlante', '1/02/2022', '36', '496320710'),
                                    ('410', '1', '6', 'Atlante', '1/02/2022', '13', '496320710'),
                                    ('170','5','7', 'Cristallo', '20/06/2022', '35', '208913249'),
                                    ('30', '1', '8', 'IVM1', '25/07/2005', '10', '968720710'),
                                    ('80', '1', '9', 'IVM2', '25/08/2005', '30', '968720710'),
                                    ('120', '1', '10', 'IVM3', '25/09/2005', '15', '968720710'),
                                    ('150', '1', '11', 'IVM4', '25/07/2015', '10', '968720710'),
                                    ('170', '1', '12', 'IVM5', '25/07/2022', '10', '968720710'),
                                    ('200', '1', '13', 'IVM6', '25/07/2005', '10', '968720710'),
                                    ('230', '1', '14', 'IVM7', '25/07/2005', '10', '968720710'),
                                    ('300', '1', '15', 'IVM8', '25/07/2005', '10', '968720710'),
                                    ('340', '1', '16', 'IVM9', '25/07/2005', '10', '968720710'),
                                    ('20', '1', '17', 'IVM10', '25/07/2005', '10', '968720710'),
                                    ('230', '1', '18', 'Bosch', '25/07/2005', '10', '968720710'),
                                    ('350', '1', '19', 'IVM11', '25/07/2005', '10', '968720710'),
                                    ('400', '1', '20', 'IVM12', '25/07/2005', '10', '968720710'),
                                    ('440', '1', '21', 'IVM13', '25/07/2005', '10', '968720710'),
                                    ('470', '1', '22', 'IVM14', '25/07/2005', '10', '968720710');

                    
                            
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

--- 2.1.

SELECT DISTINCT name_
FROM retalhista 
WHERE NOT EXISTS (
SELECT nome
FROM categoria_simples 
EXCEPT
SELECT nome_cat
FROM (responsavel_por JOIN retalhista
ON responsavel_por.tin = retalhista.tin) AS RR
WHERE RR.name_=retalhista.name_);

---3.

SELECT ean 
FROM produto 
WHERE ean NOT IN (SELECT ean FROM evento_reposicao);

--- 4.
SELECT ean 
FROM (SELECT DISTINCT ean, tin FROM evento_reposicao) AS count_ean
GROUP BY ean 
HAVING COUNT(ean) = 1;
*/
--------------------------------------------------
CREATE OR REPLACE VIEW vendas AS
SELECT ean,
    prat.nome AS cat, 
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
    FROM prateleira AS prat NATURAL JOIN evento_reposicao
        NATURAL JOIN instalada_em  
        JOIN ponto_de_retalho ON local_ = ponto_de_retalho.nome;


---------------------------------------------
--OLAP
---------------------------------------------
/*
-- 1.
SELECT  dia_semana, concelho, SUM(unidades) 
FROM vendas 
WHERE (ano > 2022 OR (ano = 2022  AND ( mes > 5 OR  ( mes=5 AND (dia_mes >= 21))))) 
AND (ano<2023 OR (ano=2023 AND (mes < 2 OR (mes = 2 AND (dia_mes <=18))))) 
GROUP BY CUBE(dia_semana,concelho) ORDER BY(dia_semana,concelho);

-- 2.
SELECT concelho, cat, dia_semana, SUM(unidades)
FROM vendas
WHERE distrito = 'Lisboa'
GROUP BY CUBE(concelho,cat,dia_semana)
ORDER BY(concelho, cat, dia_semana);

-- 2.1.
SELECT concelho, cat, dia_semana, SUM(unidades)
FROM vendas
WHERE distrito = 'Lisboa'
GROUP BY GROUPING SETS((concelho),(cat),(dia_semana),())
ORDER BY(concelho, cat, dia_semana);
*/

---------------------------------------------
--Índices
---------------------------------------------
--7.1

/*
EXPLAIN SELECT DISTINCT R.name_
 FROM retalhista R, responsavel_por P
 WHERE R.tin = P.tin and P.nome_cat = 'Frutos';

Unique  (cost=9.43..9.44 rows=1 width=178) (actual time=0.038..0.040 rows=0 loops=1)
   ->  Sort  (cost=9.43..9.43 rows=1 width=178) (actual time=0.037..0.039 rows=0 loops=1)
         Sort Key: r.name_
         Sort Method: quicksort  Memory: 25kB
         ->  Nested Loop  (cost=0.15..9.42 rows=1 width=178) (actual time=0.007..0.008 rows=0 loops=1)
               ->  Seq Scan on responsavel_por p  (cost=0.00..1.21 rows=1 width=4) (actual time=0.006..0.007 rows=0 loops=1)
                     Filter: ((nome_cat)::text = 'Frutos'::text)
                     Rows Removed by Filter: 17
               ->  Index Scan using pk_retalhista on retalhista r  (cost=0.15..8.17 rows=1 width=182) (never executed)
                     Index Cond: (tin = p.tin)
 Planning Time: 0.091 ms
 Execution Time: 0.055 ms
                    
Criamos um índice de HASH para o atributo responsavel_por.nome_cat
visto ser o melhor para seleção de igualdade de um valor específico,
mas criamos um índice Btree para o atributo responsavel_por.tin, pois,
apesar de ser usado numa igualdade, difere um pouco visto não sabermos
a quantidade de igualdades que existe entre retalhista.tin e responsavel_por.tin.
Apenas criamos índices na tabela responsavel_por pois é a única tabela presente na query
que tem atributos não primários que usamos para fazer a seleção.
*/

CREATE INDEX tin_responsavel_por_idx ON responsavel_por(tin);
CREATE INDEX cat_responsavel_por_idx ON responsavel_por USING HASH(nome_cat);

--7.2
 /*
EXPLAIN SELECT T.nome, count(T.ean)
 FROM produto P, tem_categoria T
 WHERE p.cat = T.nome and P.descr like 'A%'
 GROUP BY T.nome;

Unique  (cost=9.43..9.44 rows=1 width=178) (actual time=0.038..0.040 rows=0 loops=1)
   ->  Sort  (cost=9.43..9.43 rows=1 width=178) (actual time=0.037..0.039 rows=0 loops=1)
         Sort Key: r.name_
         Sort Method: quicksort  Memory: 25kB
         ->  Nested Loop  (cost=0.15..9.42 rows=1 width=178) (actual time=0.007..0.008 rows=0 loops=1)
               ->  Seq Scan on responsavel_por p  (cost=0.00..1.21 rows=1 width=4) (actual time=0.006..0.007 rows=0 loops=1)
                     Filter: ((nome_cat)::text = 'Frutos'::text)
                     Rows Removed by Filter: 17
               ->  Index Scan using pk_retalhista on retalhista r  (cost=0.15..8.17 rows=1 width=182) (never executed)
                     Index Cond: (tin = p.tin)
 Planning Time: 0.091 ms
 Execution Time: 0.055 ms


Criamos um índice Btree composto pois as interrogações requerem
mais que uma comparação e ambos usam igualdades não com valores extatos,
e apenas criamos na tabela produto pois é a única tabela presente na query
que tem atributos não primários que usamos para fazer a seleção.
*/

CREATE INDEX produto_idx ON produto(cat, descr);

