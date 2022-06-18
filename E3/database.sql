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
INSERT INTO categoria VALUES ('Barras'); 
INSERT INTO categoria VALUES ('Barras Energéticas');
INSERT INTO categoria VALUES ('Barras de Frutas');
INSERT INTO categoria VALUES ('Bebidas');
INSERT INTO categoria VALUES ('Refrigerantes');
INSERT INTO categoria VALUES ('Bebidas Alcoólicas');
INSERT INTO categoria VALUES ('Bebidas Energéticas');
INSERT INTO categoria VALUES ('Sumos de Fruta');
INSERT INTO categoria VALUES ('Fruta');
INSERT INTO categoria VALUES ('Legumes');
INSERT INTO categoria VALUES ('Sopas');
INSERT INTO categoria VALUES ('Sopa Miso');
INSERT INTO categoria VALUES ('Sopa de Cenoura');
INSERT INTO categoria VALUES ('Sopa de Favas');

-- Categoria Simples
INSERT INTO categoria_simples VALUES ('Barras Energéticas');
INSERT INTO categoria_simples VALUES ('Barras de Frutas');
INSERT INTO categoria_simples VALUES ('Refrigerantes');
INSERT INTO categoria_simples VALUES ('Bebidas Alcoólicas');
INSERT INTO categoria_simples VALUES ('Bebidas Energéticas');
INSERT INTO categoria_simples VALUES ('Sumos de Fruta');
INSERT INTO categoria_simples VALUES ('Fruta');
INSERT INTO categoria_simples VALUES ('Legumes');
INSERT INTO categoria_simples VALUES ('Sopa Miso');
INSERT INTO categoria_simples VALUES ('Sopa de Cenoura');
INSERT INTO categoria_simples VALUES ('Sopa de Favas');

-- Super Categoria
INSERT INTO super_categoria VALUES ('Barras'); 
INSERT INTO super_categoria VALUES ('Bebidas');
INSERT INTO super_categoria VALUES ('Sopas');

-- Tem Outra
INSERT INTO tem_outra VALUES ('Barras','Barras Energéticas');
INSERT INTO tem_outra VALUES ('Barras','Barras de Frutas');
INSERT INTO tem_outra VALUES ('Bebidas','Refrigerantes');
INSERT INTO tem_outra VALUES ('Bebidas', 'Bebidas Alcoólicas');
INSERT INTO tem_outra VALUES ('Bebidas', 'Bebidas Energéticas');
INSERT INTO tem_outra VALUES ('Bebidas', 'Sumos de Fruta');
INSERT INTO tem_outra VALUES ('Sopas', 'Sopa Miso');
INSERT INTO tem_outra VALUES ('Sopas', 'Sopa de Cenoura');
INSERT INTO tem_outra VALUES ('Sopas', 'Sopa de Favas');

INSERT INTO produto VALUES ('60','Refrigerantes','Sumol');
INSERT INTO produto VALUES ('70','Barras Energéticas','Barra Prozis');
INSERT INTO produto VALUES ('80','Fruta','Laranja');
INSERT INTO produto VALUES ('90','Legumes','Espinafre');
INSERT INTO produto VALUES ('100','Barras Energéticas','Barra MyProtein');
INSERT INTO produto VALUES ('110','Sopa Miso','Sopa Miso1');
INSERT INTO produto VALUES ('120','Bebidas Alcoólicas','Vodka');
INSERT INTO produto VALUES ('130','Refrigerantes','Coca-Cola');
INSERT INTO produto VALUES ('140','Sumos de Fruta','Sumo de Laranja');

INSERT INTO tem_categoria VALUES ('60','Refrigerantes');
INSERT INTO tem_categoria VALUES ('70','Barras Energéticas');
INSERT INTO tem_categoria VALUES ('80','Fruta');
INSERT INTO tem_categoria VALUES ('90','Legumes');
INSERT INTO tem_categoria VALUES ('100','Barras Energéticas');
INSERT INTO tem_categoria VALUES ('110','Sopa Miso');
INSERT INTO tem_categoria VALUES ('120','Bebidas Alcoólicas');
INSERT INTO tem_categoria VALUES ('130','Refrigerantes');

INSERT INTO IVM VALUES ('1','Bosch');
INSERT INTO IVM VALUES ('2','Rowenta');
INSERT INTO IVM VALUES ('3','Bosch');
INSERT INTO IVM VALUES ('4','Atlante');
INSERT INTO IVM VALUES ('5','Cristallo');

INSERT INTO ponto_de_retalho VALUES ('IST-Taguspark','Lisboa','Oeiras');
INSERT INTO ponto_de_retalho VALUES ('Repsol-Lisboa','Lisboa','Oriente');
INSERT INTO ponto_de_retalho VALUES ('Fórum-Castelo Branco','Castelo Branco','Castelo Branco');

INSERT INTO instalada_em VALUES ('1','Bosch','Repsol-Lisboa');
INSERT INTO instalada_em VALUES ('2','Rowenta','Fórum-Castelo Branco');
INSERT INTO instalada_em VALUES ('3','Bosch','IST-Taguspark');
INSERT INTO instalada_em VALUES ('4','Atlante','IST-Taguspark');
INSERT INTO instalada_em VALUES ('5','Cristallo','Fórum-Castelo Branco');


INSERT INTO prateleira VALUES ('1','1','Bosch','15','Refrigerantes');
INSERT INTO prateleira VALUES ('2','3','Bosch','15','Barras Energéticas');
INSERT INTO prateleira VALUES ('1','4','Atlante','15','Sopas');
INSERT INTO prateleira VALUES ('2','4','Atlante','15','Fruta');
INSERT INTO prateleira VALUES ('3','5','Cristallo','15','Fruta');
INSERT INTO prateleira VALUES ('6','5','Cristallo','15','Bebidas Alcoólicas');
INSERT INTO prateleira VALUES ('5','2','Rowenta','15','Sumos de Fruta');


INSERT INTO planograma(ean, nro, num_serie, fabricante, faces, unidades, loc) VALUES ('60','1','1', 'Bosch','6','48','3');
INSERT INTO planograma VALUES ('70','2','3', 'Bosch','6','48','5');
INSERT INTO planograma VALUES ('120','3','5', 'Cristallo','5','40','5');
INSERT INTO planograma VALUES ('80','2','4', 'Atlante','8','64','8');
INSERT INTO planograma VALUES ('80','6','5', 'Cristallo','5','40','2');
INSERT INTO planograma VALUES ('140','5','2', 'Rowenta','4','32','3');


INSERT INTO retalhista VALUES('102415639','Auchan');
INSERT INTO retalhista VALUES('968746229','Recheio');
INSERT INTO retalhista VALUES('208913249','Lidl');
INSERT INTO retalhista VALUES('496320710','Intermarché');
INSERT INTO retalhista VALUES('968720710','Pingo Doce');
INSERT INTO retalhista VALUES('496326229','Jumbo');


INSERT INTO responsavel_por(nome_cat, tin, num_serie, fabricante) VALUES ('Refrigerantes','102415639','1','Bosch');
INSERT INTO responsavel_por VALUES ('Barras Energéticas','968720710','3','Bosch');
INSERT INTO responsavel_por VALUES ('Sumos de Fruta','968746229','2','Rowenta');
INSERT INTO responsavel_por VALUES ('Fruta','208913249','5','Cristallo');
INSERT INTO responsavel_por VALUES ('Sopas','496320710','4','Atlante');


INSERT INTO evento_reposicao(ean, nro, num_serie, fabricante, instante, unidades, tin) VALUES ('60','1', '1','Bosch','18/02/2022','40','102415639');







  
