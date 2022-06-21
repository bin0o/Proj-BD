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


@app.route("/inserir_categoria")
def inserir_cat():
    try:
        return render_template("inserir_categoria.html", params=request.args)
    except Exception as e:
        return str(e)
    
    
@app.route("/update_categoria", methods=["POST"])
def update_categoria():
    dbConn = None
    cursor = None
    try:
        dbConn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        balance = request.form["balance"]
        account_number = request.form["account_number"]
        query = "UPDATE account SET balance=%s WHERE account_number = %s"
        data = (balance, account_number)
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

# @app.route("/update", methods=["POST"])
# def update_balance():
#     dbConn = None
#     cursor = None
#     try:
#         dbConn = psycopg2.connect(DB_CONNECTION_STRING)
#         cursor = dbConn.cursor(cursor_factory=psycopg2.extras.DictCursor)
#         balance = request.form["balance"]
#         account_number = request.form["account_number"]
#         query = "UPDATE account SET balance=%s WHERE account_number = %s"
#         data = (balance, account_number)
#         cursor.execute(query, data)
#         return query
#     except Exception as e:
#         return str(e)
#     finally:
#         dbConn.commit()
#         cursor.close()
#         dbConn.close()


CGIHandler().run(app)
