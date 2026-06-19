from app import db

class Room(db.Model):
    __tablename__ = 'rooms'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    price = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(20), default='available')
    
    # Chi tiết phòng
    area = db.Column(db.Float, nullable=True)
    floor = db.Column(db.String(50), nullable=True)
    furniture = db.Column(db.String(255), nullable=True)
    description = db.Column(db.Text, nullable=True)
    
    # Cấu hình dịch vụ
    electricityPrice = db.Column(db.Float, default=3500.0)
    waterPrice = db.Column(db.Float, default=25000.0)
    internetPrice = db.Column(db.Float, default=100000.0)
    servicePrice = db.Column(db.Float, default=50000.0)

    # Hồ sơ khách thuê & hợp đồng
    tenantName = db.Column(db.String(100), nullable=True)
    tenantPhone = db.Column(db.String(20), nullable=True)
    tenantCCCD = db.Column(db.String(50), nullable=True)
    tenantAddress = db.Column(db.Text, nullable=True)
    contractDeposit = db.Column(db.Float, nullable=True)
    contractStartDate = db.Column(db.String(50), nullable=True) 
    contractEndDate = db.Column(db.String(50), nullable=True)

    def to_dict(self):
        return {
            'id': self.id, 
            'name': self.name, 
            'price': self.price, 
            'status': self.status,
            'area': self.area,
            'floor': self.floor,
            'furniture': self.furniture,
            'description': self.description,
            'electricityPrice': self.electricityPrice,
            'waterPrice': self.waterPrice,
            'internetPrice': self.internetPrice,
            'servicePrice': self.servicePrice,
            'tenantName': self.tenantName,
            'tenantPhone': self.tenantPhone,
            'tenantCCCD': self.tenantCCCD,
            'tenantAddress': self.tenantAddress,
            'contractDeposit': self.contractDeposit,
            'contractStartDate': self.contractStartDate,
            'contractEndDate': self.contractEndDate,
        }