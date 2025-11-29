import requests
from datetime import datetime
import hashlib
from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form
from pydantic import BaseModel, Field, EmailStr
from typing import List, Optional, Literal
from sqlalchemy import create_engine, Column, Integer, String, Float, Enum, ForeignKey, DateTime
from sqlalchemy.dialects.mysql import DECIMAL
from sqlalchemy.orm import sessionmaker, declarative_base, relationship
from starlette.middleware.cors import CORSMiddleware
import shutil
import os
from fastapi.staticfiles import StaticFiles
app = FastAPI(title="API de PaqueteExpress")

#Configuración de la base de datos

DATABASE_URL = "mysql+mysqlconnector://root:root123@localhost:3309/evaluacion"

#Creamos el motor de la conexion

engine = create_engine(DATABASE_URL)

#Configuramos la sesión

SessionLocal=sessionmaker(bind=engine)


#Base

Base = declarative_base()

#Inicializamos la api




#CREAMOS LA RUTA DE DONDE SE VA SUBIR LAS FOTOS:

#Inicializa la aplicación FastAPI

app = FastAPI()
#Crea una carptea 'uploads' como ruta accesible públicamente desde el navegador
#Crea la carpeta si no existe
if not os.path.exists("uploads"):
    os.makedirs("uploads")
#Esto permite acceder a las imágenes subidasa mediante URLS como /uploads/foto.png
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


#CONFIGURACIÓN DE LOS CORS

app.add_middleware(
    CORSMiddleware,
    allow_origins = ['*'],  #Todos los origenes
    allow_methods = ['*'],
    allow_credentials = True,
    allow_headers = ['*']   #Los encabezados
)

#Modelado de SQLALCHEMY (BASE)

class Repartidor(Base):
    __tablename__ = "repartidor"
    id_r = Column(Integer, primary_key=True, autoincrement=True)
    r_nomC = Column(String(255), nullable=False)
    r_correo = Column(String(255), nullable=False)
    r_pass = Column(String(255), nullable=False)

    paquetes = relationship("Paquete", back_populates="repartidor")
    entregas= relationship("Entrega", back_populates="repartidor")

class Paquete(Base):
    __tablename__ = "paquetes"
    id_pq = Column(Integer, primary_key=True, autoincrement=True)
    colonia = Column(String(255), nullable=False)
    calle = Column(String(255), nullable=False)
    numero = Column(Integer, nullable=False)
    codigo_postal =Column(Integer, nullable=False)
    destinatario = Column(String(255), nullable=False)
    estado = Column(Enum("Sin entregar", "Entregado"), default="Sin entregar", nullable=False)
    id_rep = Column(Integer, ForeignKey('repartidor.id_r'), nullable=False)

    repartidor = relationship("Repartidor", back_populates="paquetes")
    entregas = relationship("Entrega", back_populates="paquete")

class Entrega(Base):
    __tablename__ = "entregas"

    id_e = Column(Integer, primary_key=True, autoincrement=True)
    id_p = Column(Integer, ForeignKey("paquetes.id_pq"), nullable=False)
    id_re = Column(Integer, ForeignKey("repartidor.id_r"), nullable=False)
    latitud = Column(DECIMAL(10, 7), nullable=False)
    longitud = Column(DECIMAL(11, 7), nullable=False)
    direccion = Column(String(255))
    ruta_foto = Column(String(255), nullable=True)
    fecha = Column(DateTime, default=datetime.utcnow)

    paquete = relationship("Paquete", back_populates="entregas")
    repartidor = relationship("Repartidor", back_populates="entregas")

class Admin(Base):
    __tablename__ = "Admin"
    id = Column(Integer, primary_key=True)
    nombre = Column(String(255), nullable=False)
    correo =Column(String(255), nullable=False)
    password = Column(String(255), nullable=False)


#Creamos las bases de dstos si no existe

Base.metadata.create_all(bind=engine)

#Esquemas

#--------Modelo para inicio de sesión del admin
class LoginAdmin(BaseModel):
    correo: EmailStr
    password: str

 #-------Modelo para crear un transportista
class RepartidorCrear(BaseModel):
    nombre: str
    correo: str
    password : str

#---------Modelo para el login de los repartidores
class LoginModel(BaseModel):
    correo: EmailStr
    password: str

#--------Modelo para la entrega
class EntregaModel(BaseModel):
    id_rep: int #Id de repartidor
    id_pq: int  #Id del paquete
    latitud: float #Latitud
    longitud: float #Lonfitud

#----Cambiar el estado del paquete
class EstadoPaquete(BaseModel):
    estado : Literal["Sin entregar", "En camino", "Entregado"]

#-----------Crear paquete-------------
class PaqueteCrear(BaseModel):
    colonia: str
    calle: str
    codigo_postal: int
    numero: int
    destinatario: str
    id_rep: int


#--------Modelo para enviar los paquetes--------

class PaquetesOut(BaseModel):
    id_pq: int
    calle: str
    colonia:str
    codigo_postal: int
    numero: int
    destinatario: str
    estado: str
    id_rep: int

    class Config:
        from_attributes = True
#-----------Entrega Foto-------------------

class FotoEntrega(BaseModel):
    id_en: int

#ENDPOINTS

#----------Hashear contraseña
def md5_hash(password: str) -> str:
    return hashlib.md5(password.encode()).hexdigest()
#-----------OBTENER REPARTIDORES-

@app.get("/transportistas/")
def obtener_transportista():

    db = SessionLocal()
    transportistas = db.query(Repartidor).all()

    if not transportistas:
        raise HTTPException(status_code=404, detail="Transportistas no encontrado")

    return transportistas

@app.get("/transportista/{id_rep}")
def obtener_transportista(id_rep: int):

    db = SessionLocal()
    transportista = db.query(Repartidor).filter(
        Repartidor.id_r == id_rep
    ).first()

    if not transportista:
        raise HTTPException(status_code=404, detail="Transportista no encontrado")

    return transportista



#--------------Crear transportista---

@app.post("/transportista/crear")

def crear(data: RepartidorCrear):

    db = SessionLocal()

    correo_exi = db.query(Repartidor).filter(Repartidor.r_correo == data.correo).first()
    if correo_exi:
        db.close()
        raise HTTPException(status_code=400, detail="El correo ya existe")

    hashed_pw = md5_hash(data.password)
    nuevo = Repartidor(
        r_nomC= data.nombre,
        r_correo= data.correo,
        r_pass= hashed_pw
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    db.close()
    return nuevo



#--------Login Admin-----------

@app.post("/login/admin")
def loginAdmin(data: LoginAdmin):
    db = SessionLocal()

    usuario = db.query(Admin).filter(Admin.correo == data.correo).first()

    if not usuario:
        raise HTTPException(status_code=400, detail="Admin no encontrado")
    if usuario.password != data.password:
        raise HTTPException(status_code=401, detail="Contraseña incorrecta")

    return {
        "id": usuario.id }
#----------------LOGIN TRANSPORTISTA---------------

@app.post("/login")
def login(datos: LoginModel):

    db= SessionLocal()

    usuario = db.query(Repartidor).filter(Repartidor.r_correo == datos.correo).first()

    hashed_pw = md5_hash(datos.password)
    if not usuario:
        raise  HTTPException(status_code=400, detail="Usuario no encontrado")
    if usuario.r_pass != hashed_pw:
        raise HTTPException(status_code=401, detail="Contraseña incorrecta")

    return usuario

#------------------LISTAS PAQUETES POR TRANSPORTISTA------------------------

@app.get("/paquetes/propios/{id_repa}", response_model=List[PaquetesOut])

def listar(id_repa: int):
    db = SessionLocal()

    paquetes = db.query(Paquete).filter(Paquete.id_rep == id_repa).all() #Obtiene todos los paquetes
    return paquetes #Los regresa


#----------------REALIZAR ENTREGA----------------
@app.post("/entrega/")
async def entregar(
    id_rep: int = Form(...),
    id_pq: int = Form(...),
    latitud: float = Form(...),
    longitud: float = Form(...),
    file: UploadFile = File(...)
):
    db = SessionLocal()
    try:
        repartidor = db.query(Repartidor).filter(Repartidor.id_r == id_rep).first()
        paquete = db.query(Paquete).filter(Paquete.id_pq == id_pq).first()

        if not repartidor:
            raise HTTPException(status_code=404, detail="No se encontró al repartidor")
        if not paquete:
            raise HTTPException(status_code=404, detail="No se encontró al paquete")

        # Verificamos que el paquete este asignado al repartidor
        if paquete.id_rep != id_rep:
            raise HTTPException(status_code=404, detail="Este paquete no esta asignado")

        # Obtener la dirección usando Nominatim
        try:
            url = f"https://nominatim.openstreetmap.org/reverse?format=json&lat={latitud}&lon={longitud}"
            headers = {"User-Agent": "FastAPIApp/1.0"}
            resp = requests.get(url, headers=headers, timeout=10)
            if resp.status_code == 200:
                j = resp.json()
                address = j.get("display_name", "Direccion no disponible")
            else:
                address = "Dirección no disponible"
        except Exception:
            address = "Dirección no disponible"

        # Generamos nombre para el archivo
        fecha = datetime.now().strftime("%Y%m%d_%H%M%S")
        extension = os.path.splitext(file.filename)[1]
        filename = f"entrega_{id_pq}_{fecha}{extension}"
        ruta = f"uploads/{filename}"

        # Guardamos el archivo
        with open(ruta, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Creamos la entrega
        entrega = Entrega(
            id_p=id_pq,
            id_re=id_rep,
            latitud=latitud,
            longitud=longitud,
            direccion=address,
            ruta_foto=filename
        )

        db.add(entrega)
        db.commit()
        db.refresh(entrega)

        # Actualizamos su estado a entregado:
        paquete.estado = "Entregado"
        db.commit()

        return {
            "mensaje": "Entrega registrada correctamente",
            "id_entrega": entrega.id_e,
            "ruta_foto": filename,
            "url_foto": f"/uploads/{filename}",
            "direccion": address
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")
    finally:
        db.close()

#-------------CREAR PAQUETE--------------
@app.post("/paquetes/crear/")
def crear_paquete(data: PaqueteCrear):
    db = SessionLocal()
    try:
        # Verificar que el repartidor existe
        repartidor = db.query(Repartidor).filter(Repartidor.id_r == data.id_rep).first()
        if not repartidor:
            raise HTTPException(status_code=404, detail="Repartidor no encontrado")

        nuevo = Paquete(
            colonia=data.colonia,
            calle=data.calle,
            numero=data.numero,
            codigo_postal=data.codigo_postal,
            destinatario=data.destinatario,
            id_rep=data.id_rep
        )
        db.add(nuevo)
        db.commit()
        db.refresh(nuevo)

        return {
            "mensaje": "Paquete creado exitosamente",
            "id_paquete": nuevo.id_pq,
            "calle": nuevo.calle,
            "numero": nuevo.numero,
            "colonia": nuevo.colonia,
            "codigo_postal": nuevo.codigo_postal,
            "destinario": nuevo.destinatario
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")
    finally:
        db.close()
