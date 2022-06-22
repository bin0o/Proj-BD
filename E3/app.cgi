#!/usr/bin/python3
from wsgiref.handlers import CGIHandler
from flask import Flask
from flask import render_template, request
import psycopg2
import psycopg2.extras

## SGBD configs
DB_HOST = "db.tecnico.ulisboa.pt"
DB_USER = ""
DB_DATABASE = DB_USER
DB_PASSWORD = ""
DB_CONNECTION_STRING = "host=%s dbname=%s user=%s password=%s" % (
    DB_HOST,
    DB_DATABASE,
    DB_USER,
    DB_PASSWORD,
)

app = Flask(__name__)


@app.route("/")
def index():
    try:
        return render_template("index.html", params=request.args)
    except Exception as e:
        return str(e)  # Renders a page with the error.


@app.route("/categorias")
def lista_cats():
    dbConn = None
    cursor = None
    try:
        dbConn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        query = "SELECT * FROM categoria"
        cursor.execute(query)
        return render_template("categoria.html", cursor=cursor)
    except Exception as e:
        return str(e)
    finally:
        cursor.close()
        dbConn.close()


@app.route("/inserir_categoria_simples")
def inserir_cat_simples():
    try:
        return render_template("inserir_cat_simples.html", params=request.args)
    except Exception as e:
        return str(e)
    
@app.route("/inserir_super_categoria")
def inserir_supercat():
    dbConn = None
    cursor = None
    try:
        dbConn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        query = "SELECT * FROM categoria"
        cursor.execute(query)
        return render_template("inserir_super_cat.html", cursor=cursor)
    except Exception as e:
        return str(e)
    finally:
        cursor.close()
        dbConn.close()


@app.route("/update_categoria_simples", methods=["POST"])
def update_categoria_simples():
    dbConn = None
    cursor = None
    try:
        dbConn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        name = request.form["name"]
        query = "INSERT INTO categoria VALUES(%s)"
        data = (name,)
        cursor.execute(query, data)
        query = "INSERT INTO categoria_simples VALUES(%s)"
        data = (name,)
        cursor.execute(query, data)
        return query
    except Exception as e:
        return str(e)
    finally:
        dbConn.commit()
        cursor.close()
        dbConn.close()
        
@app.route("/update_super_categoria", methods=["POST"])
def update_super_categoria():
    dbConn = None
    cursor = None
    try:
        dbConn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        name = request.form["name"]
        name_outra = request.form["name_outra"]
        query = "INSERT INTO categoria VALUES(%s)"
        data = (name,)
        cursor.execute(query, data)
        query = "INSERT INTO super_categoria VALUES(%s)"
        data = (name,)
        cursor.execute(query, data)
        query = "INSERT INTO tem_outra VALUES(%s, %s)"
        data = (name, name_outra)
        cursor.execute(query, data)
        return query
    except Exception as e:
        return str(e)
    finally:
        dbConn.commit()
        cursor.close()
        dbConn.close()
        
        
@app.route("/remover_categoria")
def remover_cat():
    try:
        return render_template("remover_categoria.html", params=request.args)
    except Exception as e:
        return str(e)


@app.route("/update_rem_categoria", methods=["POST"])
def remove_categoria():
    dbConn = None
    cursor = None
    try:
        dbConn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        nome = request.form["nome"]
        query = "DELETE FROM categoria WHERE nome=%s"
        data = (nome,)
        cursor.execute(query, data)
        return query
    except Exception as e:
        return str(e)
    finally:
        dbConn.commit()
        cursor.close()
        dbConn.close()
        
        
@app.route("/retalhistas")
def lista_rets():
    dbConn = None
    cursor = None
    try:
        dbConn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        query = "SELECT * FROM retalhista"
        cursor.execute(query)
        return render_template("retalhista.html", cursor=cursor)
    except Exception as e:
        return str(e)
    finally:
        cursor.close()
        dbConn.close()    
        
@app.route("/inserir_retalhista")
def inserir_retalhista():
    dbConn = None
    cursor = None
    try:
        dbConn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        query = "SELECT nome,num_serie,fabricante FROM prateleira WHERE (num_serie,fabricante) NOT IN (SELECT num_serie,fabricante FROM responsavel_por)"
        cursor.execute(query)
        return render_template("inserir_retalhista.html", cursor=cursor)
    except Exception as e:
        return str(e)
    finally:
        cursor.close()
        dbConn.close()
    
    
@app.route("/update_retalhista", methods=["POST"])
def update_retalhista():
    dbConn = None
    cursor = None
    try:
        dbConn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        tin = request.form["tin"]
        nome = request.form["nome"]
        name_cat = request.form["name_cat"]
        num_serie = request.form["num_serie"]
        fab = request.form["fab"]
        query = "INSERT INTO retalhista VALUES(%s,%s)"
        data = (tin,nome)
        cursor.execute(query, data)
        query = "INSERT INTO responsavel_por VALUES(%s,%s,%s,%s)"
        data = (name_cat,tin,num_serie,fab)
        cursor.execute(query, data)
        return query
    except Exception as e:
        return str(e)
    finally:
        dbConn.commit()
        cursor.close()
        dbConn.close()   
        
        
@app.route("/remover_retalhista")
def remover_ret():
    try:
        return render_template("remover_retalhista.html", params=request.args)
    except Exception as e:
        return str(e) 
    
    
    
@app.route("/update_rem_retalhista", methods=["POST"])
def remove_retalhista():
    dbConn = None
    cursor = None
    try:
        dbConn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        tin = request.form["tin"]
        query = "DELETE FROM retalhista WHERE tin=%s"
        data = (tin,)
        cursor.execute(query, data)
        return query
    except Exception as e:
        return str(e)
    finally:
        dbConn.commit()
        cursor.close()
        dbConn.close()

@app.route("/eventos")
def lista_eventos():
    dbConn = None
    cursor = None
    try:
        dbConn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        query = "SELECT nome,SUM(unidades_evento) FROM evento_reposicao NATURAL JOIN tem_categoria GROUP BY nome"
        cursor.execute(query)
        return render_template("eventos.html", cursor=cursor)
    except Exception as e:
        return str(e)
    finally:
        cursor.close()
        dbConn.close() 

CGIHandler().run(app)
