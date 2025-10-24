#!/bin/bash

# Script de sauvegarde RSYNC pour macOS
# Sauvegarde des fichiers du répertoire home vers un répertoire synchronisé avec iCloud Drive

set -euo pipefail

# Récupérer le chemin du script pour déterminer où se trouve la config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/backup.conf"

# Fonction pour logger avec timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Fonction pour lire le fichier de configuration
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "ERREUR: Fichier de configuration $CONFIG_FILE introuvable"
        exit 1
    fi

    # Charger le fichier de configuration
    source "$CONFIG_FILE"

    # Vérifier les variables requises
    if [[ -z "${SOURCE_DIR:-}" ]]; then
        log "ERREUR: SOURCE_DIR n'est pas défini dans la configuration"
        exit 1
    fi

    if [[ -z "${DEST_DIR:-}" ]]; then
        log "ERREUR: DEST_DIR n'est pas défini dans la configuration"
        exit 1
    fi

    if [[ -z "${BACKUP_ITEMS_FILE:-}" ]]; then
        log "ERREUR: BACKUP_ITEMS_FILE n'est pas défini dans la configuration"
        exit 1
    fi

    # Valeurs par défaut
    LOG_FILE="${LOG_FILE:-$SCRIPT_DIR/backup.log}"
    EXCLUDE_FILE="${EXCLUDE_FILE:-$SCRIPT_DIR/exclude.txt}"
}

# Fonction pour vérifier que les répertoires existent
check_directories() {
    if [[ ! -d "$SOURCE_DIR" ]]; then
        log "ERREUR: Le répertoire source $SOURCE_DIR n'existe pas"
        exit 1
    fi

    # Créer le répertoire de destination s'il n'existe pas
    if [[ ! -d "$DEST_DIR" ]]; then
        log "Création du répertoire de destination $DEST_DIR"
        mkdir -p "$DEST_DIR"
    fi
}

# Fonction pour préparer le fichier d'exclusion
prepare_exclude_file() {
    if [[ -f "$EXCLUDE_FILE" ]]; then
        log "Utilisation du fichier d'exclusion: $EXCLUDE_FILE"
        return 0
    fi

    # Créer un fichier d'exclusion par défaut
    cat > "$EXCLUDE_FILE" << 'EOF'
# Fichiers et répertoires à exclure de la sauvegarde
.DS_Store
.Trashes
.Spotlight-V100
.fseventsd
.TemporaryItems
.apdisk
*.tmp
*.temp
*.cache
*.log
~/.npm
~/.cache
~/.Trash
~/.local/share/Trash
~/Library/Caches
~/Library/Developer
EOF
    log "Création du fichier d'exclusion par défaut: $EXCLUDE_FILE"
}

# Fonction pour effectuer la sauvegarde d'un élément
backup_item() {
    local item="$1"
    local source_path="$SOURCE_DIR/$item"
    local dest_path="$DEST_DIR/$item"

    if [[ ! -e "$source_path" ]]; then
        log "AVERTISSEMENT: $item n'existe pas, ignoré"
        return 0
    fi

    log "Sauvegarde de $item..."

    # Options RSYNC:
    # -a: mode archive (préserve les permissions, timestamps, etc.)
    # -v: mode verbose
    # -h: format lisible par l'homme
    # --progress: affiche la progression
    # --delete: supprime les fichiers dans la destination s'ils n'existent plus dans la source
    # --exclude-from: utilise le fichier d'exclusion
    # --log-file: fichier de log RSYNC
    /opt/homebrew/bin/rsync -avh --progress --delete \
        --exclude-from="$EXCLUDE_FILE" \
        --log-file="$LOG_FILE" \
        "$source_path" "$dest_path"

    if [[ $? -eq 0 ]]; then
        log "Sauvegarde de $item terminée avec succès"
    else
        log "ERREUR lors de la sauvegarde de $item"
        return 1
    fi
}

# Fonction pour exporter la liste des paquets Homebrew
export_homebrew_list() {
    log "Exportation de la liste des paquets Homebrew..."

    # Vérifier si Homebrew est installé
    if ! command -v /opt/homebrew/bin/brew &> /dev/null; then
        log "AVERTISSEMENT: Homebrew n'est pas installé, export ignoré"
        return 0
    fi

    # Créer le répertoire local pour les exports Homebrew
    local homebrew_export_dir="$HOME/.macbackups-homebrew"
    mkdir -p "$homebrew_export_dir"

    # Exporter la liste des paquets (formulas)
    local formulas_file="$homebrew_export_dir/brew-formulas.txt"
    /opt/homebrew/bin/brew list --formula > "$formulas_file" 2>/dev/null || {
        log "ERREUR: Impossible d'exporter la liste des formulas Homebrew"
        return 1
    }
    log "Liste des formulas exportée: $formulas_file"

    # Exporter la liste des casks (applications)
    local casks_file="$homebrew_export_dir/brew-casks.txt"
    /opt/homebrew/bin/brew list --cask > "$casks_file" 2>/dev/null || {
        log "AVERTISSEMENT: Impossible d'exporter la liste des casks Homebrew (pas de casks installés?)"
    }
    log "Liste des casks exportée: $casks_file"

    # Créer/mettre à jour le script de restauration (un seul fichier, pas de versionnement)
    local restore_script="$homebrew_export_dir/restore-homebrew.sh"
    cat > "$restore_script" << 'EOF'
#!/bin/bash

# Script de restauration des paquets Homebrew
# Généré automatiquement par MacBackups
# Utilise les fichiers d'export les plus récents disponibles

set -euo pipefail

echo "Restauration des paquets Homebrew..."

# Vérifier si Homebrew est installé
if ! command -v /opt/homebrew/bin/brew &> /dev/null; then
    echo "ERREUR: Homebrew n'est pas installé. Veuillez d'abord installer Homebrew:"
    echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Mettre à jour Homebrew
echo "Mise à jour de Homebrew..."
/opt/homebrew/bin/brew update

# Répertoire contenant les exports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Fichiers fixes à utiliser (dans le répertoire homebrew-exports)
FORMULAS_FILE="$SCRIPT_DIR/homebrew-exports/brew-formulas.txt"
CASKS_FILE="$SCRIPT_DIR/homebrew-exports/brew-casks.txt"

# Restaurer les formulas
if [[ -f "$FORMULAS_FILE" ]]; then
    echo "Installation des formulas depuis: $(basename "$FORMULAS_FILE")"
    xargs /opt/homebrew/bin/brew install < "$FORMULAS_FILE"
else
    echo "AVERTISSEMENT: Fichier de formulas introuvable"
fi

# Restaurer les casks
if [[ -f "$CASKS_FILE" ]]; then
    echo "Installation des casks depuis: $(basename "$CASKS_FILE")"
    xargs /opt/homebrew/bin/brew install --cask < "$CASKS_FILE"
else
    echo "AVERTISSEMENT: Fichier de casks introuvable"
fi

echo "Restauration terminée!"
EOF

    chmod +x "$restore_script"
    log "Script de restauration mis à jour: $restore_script"

    return 0
}

# Fonction principale de sauvegarde
perform_backup() {
    log "Début de la sauvegarde"
    log "Configuration: $CONFIG_FILE"
    log "Source: $SOURCE_DIR"
    log "Destination: $DEST_DIR"

    # Vérifier les répertoires
    check_directories

    # Exporter la liste des paquets Homebrew
    export_homebrew_list

    # Préparer le fichier d'exclusion
    prepare_exclude_file

    # Vérifier que le fichier d'items existe
    if [[ ! -f "$BACKUP_ITEMS_FILE" ]]; then
        log "ERREUR: Fichier d'items $BACKUP_ITEMS_FILE introuvable"
        exit 1
    fi

    # Lire les éléments à sauvegarder depuis le fichier (un par ligne)
    # Utiliser une méthode compatible avec toutes les versions de bash
    local items=()
    while IFS= read -r line; do
        items+=("$line")
    done < "$BACKUP_ITEMS_FILE"

    local success_count=0
    local error_count=0

    # Sauvegarder chaque élément
    for item in "${items[@]}"; do
        # Ignorer les lignes vides et les commentaires
        if [[ -n "$item" && ! "$item" =~ ^[[:space:]]*# ]]; then
            if backup_item "$item"; then
                ((success_count++))
            else
                ((error_count++))
            fi
        fi
    done

    log "Sauvegarde terminée: $success_count succès, $error_count erreurs"

    if [[ $error_count -gt 0 ]]; then
        exit 1
    fi
}

# Fonction de nettoyage des anciens logs
cleanup_logs() {
    if [[ -n "${LOG_RETENTION_DAYS:-}" && "$LOG_RETENTION_DAYS" -gt 0 ]]; then
        log "Nettoyage des logs de plus de $LOG_RETENTION_DAYS jours"
        find "$(dirname "$LOG_FILE")" -name "$(basename "$LOG_FILE")*" -type f -mtime "+$LOG_RETENTION_DAYS" -delete 2>/dev/null || true
    fi
}

# Point d'entrée principal
main() {
    # Charger la configuration
    load_config

    # Créer le répertoire de logs si nécessaire
    mkdir -p "$(dirname "$LOG_FILE")"

    # Logger le début
    log "=== DÉBUT DE LA SAUVEGARDE ==="

    # Effectuer la sauvegarde
    perform_backup

    # Nettoyer les anciens logs
    cleanup_logs

    log "=== SAUVEGARDE TERMINÉE ==="
}

# Exécuter la fonction principale
main "$@"
