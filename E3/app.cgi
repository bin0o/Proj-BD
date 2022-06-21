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
        query = "SELECT * FROM categoria;"
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
    try:
        return render_template("inserir_super_cat.html", params=request.args)
    except Exception as e:
        return str(e)


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
        query = "INSERT INTO categoria VALUES(%s)"
        data = (name,)
        cursor.execute(query, data)
        query = "INSERT INTO super_categoria VALUES(%s)"
        data = (name,)
        cursor.execute(query, data)
        return query
    except Exception as e:
        return str(e)
    finally:
        dbConn.commit()
        cursor.close()
        dbConn.close()
        
        
@app.route("/categorias/remover_categoria")
def remover_cat():
    try:
        return render_template("remover_categoria.html", params=request.args)
    except Exception as e:
        return str(e)


@app.route("/remove_categoria")
def remove_categoria():
    dbConn = None
    cursor = None
    try:
        dbConn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        nome = request.form["nomr"]
        query = "DELETE categoria VALUES(%s)"
        data = (nome,)
        cursor.execute(query, data)
        return query
    except Exception as e:
        return str(e)
    finally:
        dbConn.commit()
        cursor.close()
        dbConn.close()

CGIHandler().run(app)
