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
DROP TABLE IF EXISTS responsável_por CASCADE;
DROP TABLE IF EXISTS evento_reposicao CASCADE;
DROP SEQUENCE IF EXISTS instalada_em_num_serie_seq CASCADE;
DROP SEQUENCE IF EXISTS ivm_num_serie_seq CASCADE;
DROP SEQUENCE IF EXISTS planograma_num_serie_seq CASCADE;
DROP SEQUENCE IF EXISTS responsável_por_num_serie_seq CASCADE;


 
CREATE TABLE categoria
    (nome VARCHAR(80) NOT NULL,
     PRIMARY KEY(nome));

CREATE TABLE categoria_simples
    (nome VARCHAR(80) NOT NULL,
     PRIMARY KEY(nome),
     FOREIGN KEY(nome) REFERENCES categoria(nome));

CREATE TABLE super_categoria
    (nome VARCHAR(80) NOT NULL,
     PRIMARY KEY(nome),
     FOREIGN KEY(nome) REFERENCES categoria(nome));

CREATE TABLE tem_outra
    (super_categoria CHAR(20) NOT NULL,
     categoria CHAR(20) NOT NULL,
     PRIMARY KEY(categoria),
     FOREIGN KEY(categoria) REFERENCES categoria(nome),
     FOREIGN KEY(super_categoria) REFERENCES super_categoria(nome));

CREATE TABLE produto 
    (ean INT NOT NULL,
     descr VARCHAR(200) NOT NULL,
     cat VARCHAR(80) NOT NULL,
     PRIMARY KEY(ean),
     FOREIGN KEY(cat) REFERENCES categoria(nome));

CREATE TABLE tem_categoria
    (ean INT NOT NULL,
     nome VARCHAR(80) NOT NULL,
     FOREIGN KEY(ean) REFERENCES produto(ean),
     FOREIGN KEY(nome) REFERENCES categoria(nome));

CREATE TABLE IVM 
    (num_serie SERIAL NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     PRIMARY KEY(num_serie,fabricante));

CREATE TABLE ponto_de_retalho
    (nome VARCHAR(50) NOT NULL,
     distrito VARCHAR(20) NOT NULL,
     concelho VARCHAR(20) NOT NULL,
     PRIMARY KEY(nome));

CREATE TABLE instalada_em
    (num_serie SERIAL NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     local_ VARCHAR(50) NOT NULL,
     PRIMARY KEY(num_serie, fabricante),
     FOREIGN KEY(local_) REFERENCES ponto_de_retalho(nome));

CREATE TABLE prateleira
    (nro INT NOT NULL,
     num_serie INT NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     altura INT NOT NULL,
     nome VARCHAR(80) NOT NULL,
     PRIMARY KEY(nro,num_serie, fabricante),
     FOREIGN KEY(num_serie, fabricante) REFERENCES IVM(num_serie, fabricante),
     FOREIGN KEY(nome) REFERENCES categoria(nome));

CREATE TABLE planograma
    (ean INT NOT NULL,
     nro INT NOT NULL,
     num_serie SERIAL NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     faces INT NOT NULL,
     unidades INT NOT NULL, 
     loc VARCHAR(20) NOT NULL,
     PRIMARY KEY(ean, nro, num_serie, fabricante),
     FOREIGN KEY(ean) REFERENCES produto(ean),
     FOREIGN KEY(nro, num_serie, fabricante) REFERENCES prateleira(nro, num_serie, fabricante));

CREATE TABLE retalhista
    (tin INT NOT NULL,
     name_ VARCHAR(80) NOT NULL UNIQUE,
     PRIMARY KEY(tin));

CREATE TABLE responsável_por    
    (nome_cat VARCHAR(80) NOT NULL,
     tin INT NOT NULL,
     num_serie SERIAL NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     PRIMARY KEY(num_serie, fabricante),
     FOREIGN KEY(num_serie, fabricante) REFERENCES IVM(num_serie, fabricante),
     FOREIGN KEY(tin) REFERENCES retalhista(tin),
     FOREIGN KEY(nome_cat) REFERENCES categoria(nome));

CREATE TABLE evento_reposicao
    (ean INT NOT NULL,
     nro INT NOT NULL,
     num_serie INT NOT NULL,
     fabricante VARCHAR(20) NOT NULL,
     instante DATE NOT NULL,
     unidades INT NOT NULL,
     tin INT NOT NULL,
     PRIMARY KEY(ean, nro, num_serie, fabricante, instante),
     FOREIGN KEY(tin) REFERENCES retalhista(tin));

/* manuel is a little bitch. my little bitch :) */