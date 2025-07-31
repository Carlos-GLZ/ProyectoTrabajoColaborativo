#!/bin/bash

# ============================================================================
# SCRIPT: create-infrastructure.sh
# Crea VPC, EC2 y toda la infraestructura necesaria para PitchZone en AWS
# ============================================================================

set -e  # Salir ante cualquier error

# Configuración de variables
PROJECT_NAME="pitchzone"
REGION="us-east-1"                # Cambia por tu región preferida si es necesario
KEY_NAME="pitchzone-key"
INSTANCE_TYPE="t2.micro"          # Free tier elegible

echo "🚀 Iniciando creación de infraestructura para PitchZone..."

# Crear VPC
echo "📡 Creando VPC..."
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT_NAME}-vpc},{Key=Project,Value=${PROJECT_NAME}}]" \
    --query 'Vpc.VpcId' \
    --output text \
    --region $REGION)

echo "✅ VPC creada exitosamente: $VPC_ID"

# Habilitar DNS hostname y resolution
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames --region $REGION
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support --region $REGION

# Crear Internet Gateway
echo "🌐 Creando Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${PROJECT_NAME}-igw},{Key=Project,Value=${PROJECT_NAME}}]" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text \
    --region $REGION)

echo "✅ Internet Gateway creado: $IGW_ID"

# Adjuntar Internet Gateway a VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID \
    --region $REGION

echo "✅ Internet Gateway adjuntado a VPC"

# Crear subnet pública
echo "🏗️ Creando subnet pública..."
SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone "${REGION}a" \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-public-subnet},{Key=Project,Value=${PROJECT_NAME}}]" \
    --query 'Subnet.SubnetId' \
    --output text \
    --region $REGION)

echo "✅ Subnet pública creada: $SUBNET_ID"

# Habilitar asignación automática de IP pública
aws ec2 modify-subnet-attribute \
    --subnet-id $SUBNET_ID \
    --map-public-ip-on-launch \
    --region $REGION

# Crear tabla de rutas para subnet pública
echo "🛣️ Creando tabla de rutas..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_NAME}-public-rt},{Key=Project,Value=${PROJECT_NAME}}]" \
    --query 'RouteTable.RouteTableId' \
    --output text \
    --region $REGION)

echo "✅ Tabla de rutas creada: $ROUTE_TABLE_ID"

# Crear ruta hacia Internet Gateway
aws ec2 create-route \
    --route-table-id $ROUTE_TABLE_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID \
    --region $REGION

# Asociar tabla de rutas con subnet
aws ec2 associate-route-table \
    --route-table-id $ROUTE_TABLE_ID \
    --subnet-id $SUBNET_ID \
    --region $REGION

echo "✅ Tabla de rutas configurada"

# Crear Security Group
echo "🔒 Creando Security Group..."
SG_ID=$(aws ec2 create-security-group \
    --group-name ${PROJECT_NAME}-sg \
    --description "Security group for PitchZone web server" \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT_NAME}-sg},{Key=Project,Value=${PROJECT_NAME}}]" \
    --query 'GroupId' \
    --output text \
    --region $REGION)

echo "✅ Security Group creado: $SG_ID"

# Configurar reglas del Security Group
# HTTP (puerto 80)
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region $REGION

# HTTPS (puerto 443)
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 \
    --region $REGION

# SSH (puerto 22)
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $REGION

echo "✅ Reglas de Security Group configuradas"

# Crear Key Pair si no existe
echo "🔑 Verificando/Creando Key Pair..."
if ! aws ec2 describe-key-pairs --key-names $KEY_NAME --region $REGION > /dev/null 2>&1; then
    aws ec2 create-key-pair \
        --key-name $KEY_NAME \
        --query 'KeyMaterial' \
        --output text \
        --region $REGION > ${KEY_NAME}.pem

    chmod 400 ${KEY_NAME}.pem
    echo "✅ Key Pair creado: ${KEY_NAME}.pem"
else
    echo "ℹ️ Key Pair ya existe: $KEY_NAME"
fi

# Obtener AMI ID más reciente de Amazon Linux 2
echo "🖥️ Obteniendo AMI ID más reciente..."
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text \
    --region $REGION)

echo "✅ AMI ID obtenido: $AMI_ID"

# Crear instancia EC2
echo "🚀 Creando instancia EC2..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --subnet-id $SUBNET_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PROJECT_NAME}-server},{Key=Project,Value=${PROJECT_NAME}}]" \
    --user-data file://user-data.sh \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region $REGION)

echo "✅ Instancia EC2 creada: $INSTANCE_ID"

# Esperar a que la instancia esté corriendo
echo "⏳ Esperando a que la instancia esté lista..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Obtener IP pública
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text \
    --region $REGION)

# Guardar información en archivo de configuración
cat > infrastructure-info.txt << EOF
# Información de Infraestructura PitchZone
PROJECT_NAME=$PROJECT_NAME
REGION=$REGION
VPC_ID=$VPC_ID
IGW_ID=$IGW_ID
SUBNET_ID=$SUBNET_ID
ROUTE_TABLE_ID=$ROUTE_TABLE_ID
SG_ID=$SG_ID
INSTANCE_ID=$INSTANCE_ID
PUBLIC_IP=$PUBLIC_IP
KEY_NAME=$KEY_NAME
EOF

echo ""
echo "🎉 ¡Infraestructura creada exitosamente!"
echo "📋 Información guardada en: infrastructure-info.txt"
echo "🌐 IP Pública: $PUBLIC_IP"
echo "🔑 Key Pair: ${KEY_NAME}.pem"
echo ""
echo "⏳ La instancia puede tardar unos minutos en estar completamente lista..."
echo "🌍 Tu sitio estará disponible en: http://$PUBLIC_IP"
echo ""
