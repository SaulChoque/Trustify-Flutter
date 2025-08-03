#!/bin/bash

# Script de construcción y ejecución de Trustify
# Uso: ./build_and_run.sh [clean|run|build]

set -e

PROJECT_DIR="/home/saul/Documentos/proyectos/app movil/trustify"

echo "🚀 Trustify Build Script"
echo "========================"

cd "$PROJECT_DIR"

case "${1:-run}" in
    "clean")
        echo "🧹 Limpiando proyecto..."
        flutter clean
        flutter pub get
        echo "✅ Proyecto limpio"
        ;;
    
    "build")
        echo "🔨 Construyendo APK de debug..."
        flutter build apk --debug
        echo "✅ APK construido en build/app/outputs/flutter-apk/"
        ;;
    
    "run")
        echo "📱 Ejecutando aplicación en dispositivo..."
        flutter run --debug
        ;;
    
    "analyze")
        echo "🔍 Analizando código..."
        flutter analyze
        echo "✅ Análisis completado"
        ;;
    
    *)
        echo "❌ Comando no reconocido: $1"
        echo "Uso: $0 [clean|run|build|analyze]"
        exit 1
        ;;
esac

echo "🎉 Operación completada!"
