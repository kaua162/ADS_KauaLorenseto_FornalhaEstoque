import os
from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv

from app.extensions import db

load_dotenv()


def create_app():
    app = Flask(__name__)
    app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "dev")
    app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv(
        "DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/fornalha_estoque"
    )
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

    db.init_app(app)
    CORS(app)

    from app.models import usuario, materia_prima, movimentacao_estoque  # noqa: F401
    from app.models import pizza_sabor, estoque_pizza, mercado_parceiro  # noqa: F401
    from app.models import pedido_revenda, item_pedido  # noqa: F401

    from app.routes.auth import auth_bp
    from app.routes.materia_prima import materia_prima_bp
    from app.routes.pizza_sabor import pizza_sabor_bp
    from app.routes.estoque_pizza import estoque_pizza_bp
    from app.routes.mercado_parceiro import mercado_parceiro_bp
    from app.routes.pedido_revenda import pedido_revenda_bp

    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(materia_prima_bp, url_prefix="/materia-prima")
    app.register_blueprint(pizza_sabor_bp, url_prefix="/pizza-sabor")
    app.register_blueprint(estoque_pizza_bp, url_prefix="/estoque-pizza")
    app.register_blueprint(mercado_parceiro_bp, url_prefix="/mercado-parceiro")
    app.register_blueprint(pedido_revenda_bp, url_prefix="/pedido-revenda")

    @app.get("/")
    def health():
        return {"status": "ok", "service": "fornalha-estoque-api"}

    with app.app_context():
        db.create_all()

    return app
