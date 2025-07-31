# SCRIPT 3: cleanup.sh
# Elimina toda la infraestructura creada
# ============================================================================

#!/bin/bash

# Cargar información de infraestructura
if [ ! -f "infrastructure-info.txt" ]; then
    echo "❌ No se encontró infrastructure-info.txt"
    echo "📝 No hay infraestructura que eliminar o ya fue eliminada"
    exit 1
fi

source infrastructure-info.txt

echo "🗑️ Iniciando limpieza de infraestructura de PitchZone..."
echo "⚠️ Esta acción eliminará TODA la infraestructura creada"
read -p "¿Estás seguro? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operación cancelada"
    exit 1
fi

echo "🚮 Eliminando recursos..."

# Terminar instancia EC2
if [ ! -z "$INSTANCE_ID" ]; then
    echo "🖥️ Terminando instancia EC2: $INSTANCE_ID"
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
    
    echo "⏳ Esperando a que la instancia termine..."
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID --region $REGION
    echo "✅ Instancia terminada"
fi

# Eliminar Security Group
if [ ! -z "$SG_ID" ]; then
    echo "🔒 Eliminando Security Group: $SG_ID"
    aws ec2 delete-security-group --group-id $SG_ID --region $REGION
    echo "✅ Security Group eliminado"
fi

# Desasociar y eliminar tabla de rutas
if [ ! -z "$ROUTE_TABLE_ID" ]; then
    echo "🛣️ Eliminando tabla de rutas: $ROUTE_TABLE_ID"
    
    # Obtener asociaciones de la tabla de rutas
    ASSOCIATIONS=$(aws ec2 describe-route-tables --route-table-ids $ROUTE_TABLE_ID --query 'RouteTables[0].Associations[?!Main].RouteTableAssociationId' --output text --region $REGION)
    
    # Desasociar si hay asociaciones
    if [ ! -z "$ASSOCIATIONS" ]; then
        for assoc in $ASSOCIATIONS; do
            aws ec2 disassociate-route-table --association-id $assoc --region $REGION
        done
    fi
    
    # Eliminar rutas personalizadas
    aws ec2 delete-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --region $REGION 2>/dev/null || true
    
    # Eliminar tabla de rutas
    aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID --region $REGION
    echo "✅ Tabla de rutas eliminada"
fi

# Eliminar subnet
if [ ! -z "$SUBNET_ID" ]; then
    echo "🏗️ Eliminando subnet: $SUBNET_ID"
    aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION
    echo "✅ Subnet eliminada"
fi

# Desadjuntar y eliminar Internet Gateway
if [ ! -z "$IGW_ID" ] && [ ! -z "$VPC_ID" ]; then
    echo "🌐 Desadjuntando Internet Gateway: $IGW_ID"
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
    
    echo "🌐 Eliminando Internet Gateway: $IGW_ID"
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION
    echo "✅ Internet Gateway eliminado"
fi

# Eliminar VPC
if [ ! -z "$VPC_ID" ]; then
    echo "📡 Eliminando VPC: $VPC_ID"
    aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION
    echo "✅ VPC eliminada"
fi

# Eliminar Key Pair (opcional - comentado por seguridad)
# if [ ! -z "$KEY_NAME" ]; then
#     echo "🔑 Eliminando Key Pair: $KEY_NAME"
#     aws ec2 delete-key-pair --key-name $KEY_NAME --region $REGION
#     rm -f ${KEY_NAME}.pem
#     echo "✅ Key Pair eliminado"
# fi

# Limpiar archivos locales
echo "🧹 Limpiando archivos locales..."
rm -f infrastructure-info.txt
rm -f deploy-pitchzone.sh
rm -f user-data.sh

echo ""
echo "🎉 ¡Limpieza completada exitosamente!"
echo "💰 Todos los recursos de AWS han sido eliminados"
echo "📝 El Key Pair se mantiene por seguridad: ${KEY_NAME}.pem"
echo "🗑️ Si no planeas usarlo más, elimínalo manualmente:"
echo "   aws ec2 delete-key-pair --key-name $KEY_NAME --region $REGION"
echo "   rm -f ${KEY_NAME}.pem"
echo ""