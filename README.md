# MacBackups

![Shell](https://img.shields.io/badge/Shell-Bash-blue)
![macOS](https://img.shields.io/badge/macOS-compatible-success)
![License](https://img.shields.io/badge/License-MIT-green)

Un système de sauvegarde automatisé pour macOS utilisant RSYNC pour synchroniser vos fichiers personnels vers un répertoire local (compatible iCloud Drive).

## 🌟 Fonctionnalités

- **Sauvegarde incrémentielle** : Utilise RSYNC pour ne transférer que les fichiers modifiés
- **Automatisation** : Service launchd pour exécuter les sauvegardes régulièrement
- **Personnalisable** : Configuration simple des fichiers et dossiers à sauvegarder
- **Logging complet** : Logs détaillés avec timestamps et rotation automatique
- **Exclusions intelligentes** : Filtre automatiquement les fichiers système et temporaires
- **Compatible iCloud** : Destination configurable pour synchroniser avec iCloud Drive

## 📁 Structure du projet

```
MacBackups/
├── backup.sh                 # Script principal de sauvegarde
├── backup.conf               # Fichier de configuration
├── com.user.macbackups.plist # Service launchd pour l'automatisation
├── macbackups-items.txt      # Liste des fichiers/dossiers à sauvegarder
├── .gitignore               # Fichiers à ignorer pour Git
└── README.md                # Ce fichier
```

## 🚀 Installation

### Prérequis

- **macOS 10.15+**
- **Homebrew** (pour l'installation de RSYNC)
- **RSYNC 3.4+** (version complète, pas OpenRSYNC)

### 1. Installer RSYNC complet

macOS inclus OpenRSYNC par défaut, mais il a des limitations avec iCloud Drive. Installez la version complète :

```bash
# Installer RSYNC via Homebrew
brew install rsync

# Vérifier la version
/opt/homebrew/bin/rsync --version
```

### 2. Cloner le repository

```bash
git clone https://github.com/lab34/MacBackups.git
cd MacBackups
```

### 3. Personnaliser la configuration

Éditez le fichier `backup.conf` pour adapter les chemins à votre configuration :

```bash
# Répertoire source (généralement votre home directory)
SOURCE_DIR="$HOME"

# Répertoire de destination (modifiable selon vos besoins)
DEST_DIR="$HOME/Documents/MacBackups"
# Pour iCloud Drive: "$HOME/Library/Mobile Documents/com~apple~CloudDocs/MacBackups"

# Fichier contenant la liste des éléments à sauvegarder
BACKUP_ITEMS_FILE="$HOME/.macbackups-items.txt"
```

### 4. Configurer les éléments à sauvegarder

Copiez et personnalisez le fichier des éléments à sauvegarder :

```bash
cp macbackups-items.txt ~/.macbackups-items.txt
```

Éditez `~/.macbackups-items.txt` pour ajouter/supprimer les fichiers et dossiers que vous souhaitez sauvegarder.

### 5. Créer les répertoires nécessaires

```bash
# Créer le répertoire de destination
mkdir -p "$HOME/Documents/MacBackups"

# Créer le répertoire de logs
mkdir -p "$HOME/logs"
```

### 6. Tester manuellement

```bash
chmod +x backup.sh
./backup.sh
```

### 7. Installer le service automatisé (optionnel)

```bash
# Copier le fichier de service launchd
cp com.user.macbackups.plist ~/Library/LaunchAgents/

# Charger le service
launchctl load ~/Library/LaunchAgents/com.user.macbackups.plist

# Démarrer le service
launchctl start com.user.macbackups
```

## ⚙️ Configuration

### Fichier `backup.conf`

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `SOURCE_DIR` | Répertoire source à sauvegarder | `$HOME` |
| `DEST_DIR` | Répertoire de destination | `$HOME/Documents/MacBackups` |
| `BACKUP_ITEMS_FILE` | Fichier liste des éléments à sauvegarder | `$HOME/.macbackups-items.txt` |
| `LOG_FILE` | Fichier de log | `$HOME/logs/macbackups.log` |
| `EXCLUDE_FILE` | Fichier d'exclusions RSYNC | `$HOME/.macbackups-exclude.txt` |
| `LOG_RETENTION_DAYS` | Jours de conservation des logs | `30` |

### Fichier `macbackups-items.txt`

Ce fichier contient la liste des fichiers et dossiers à sauvegarder, un par ligne :

```
Documents
Desktop
Downloads
Pictures
Projects
.config
.ssh
.bash_profile
.zshrc
```

### Exclusions automatiques

Le script crée automatiquement un fichier d'exclusion avec les éléments suivants :

- Fichiers système macOS (`.DS_Store`, `.Trashes`, `.Spotlight-V100`)
- Fichiers temporaires (`.tmp`, `.temp`, `.cache`)
- Caches et logs (`~/.npm`, `~/Library/Caches`)
- Corbeille (`~/.Trash`)

## 🔄 Utilisation

### Exécution manuelle

```bash
# Exécuter une sauvegarde immédiate
./backup.sh

# Vérifier les logs
tail -f ~/logs/macbackups.log
```

### Service automatisé

Le service launchd exécute la sauvegarde :
- **Fréquence** : Toutes les heures (3600 secondes)
- **Au démarrage** : Exécution immédiate au chargement du service
- **Priorité** : Faible priorité pour ne pas impacter les performances

#### Commandes du service

```bash
# Démarrer le service
launchctl start com.user.macbackups

# Arrêter le service
launchctl stop com.user.macbackups

# Recharger après modification du plist
launchctl unload ~/Library/LaunchAgents/com.user.macbackups.plist
launchctl load ~/Library/LaunchAgents/com.user.macbackups.plist

# Vérifier le statut
launchctl list | grep macbackups
```

## 📊 Monitoring

### Logs

- **Log principal** : `~/logs/macbackups.log`
- **Sortie standard** : `~/logs/macbackups-stdout.log`
- **Erreurs** : `~/logs/macbackups-stderr.log`

### Exemples de logs

```
[2024-01-15 14:30:00] === DÉBUT DE LA SAUVEGARDE ===
[2024-01-15 14:30:00] Configuration: /Users/labouc/dev/macbackups/backup.conf
[2024-01-15 14:30:00] Source: /Users/labouc
[2024-01-15 14:30:00] Destination: /Users/labouc/Documents/MacBackups
[2024-01-15 14:30:01] Sauvegarde de Documents...
[2024-01-15 14:30:15] Sauvegarde de Documents terminée avec succès
[2024-01-15 14:30:15] Sauvegarde terminée: 5 succès, 0 erreurs
[2024-01-15 14:30:15] === SAUVEGARDE TERMINÉE ===
```

## 🔧 Dépannage

### Problèmes courants

1. **Permission refusée**
   ```bash
   chmod +x backup.sh
   ```

2. **Répertoire de destination inexistant**
   ```bash
   mkdir -p "$HOME/Documents/MacBackups"
   ```

3. **RSYNC version incompatible**

   **Symptômes :**
   - Erreurs `mkstempsock: Invalid argument`
   - Erreurs `Operation not permitted` avec iCloud Drive

   **Solution :**
   ```bash
   # Installer la version complète de RSYNC
   brew install rsync

   # Vérifier que vous utilisez la bonne version
   /opt/homebrew/bin/rsync --version
   # Doit afficher "rsync version 3.4.x" et non "openrsync"
   ```

4. **Service ne démarre pas**
   ```bash
   # Vérifier les erreurs
   launchctl list | grep macbackups
   cat ~/logs/macbackups-stderr.log
   ```

5. **Fichiers exclus non désirés**
   - Éditez `~/.macbackups-exclude.txt` pour modifier les exclusions

6. **Erreurs avec iCloud Drive**

   **Symptômes :**
   - Erreurs de permissions avec `~/Library/Mobile Documents/`
   - Synchronisation incomplète

   **Solutions :**
   - Assurez-vous d'utiliser RSYNC 3.4+ (voir point 3)
   - Vérifiez que iCloud Drive est activé et synchronisé
   - Testez avec un répertoire local avant d'utiliser iCloud Drive

### Réinitialisation complète

```bash
# Arrêter le service
launchctl stop com.user.macbackups
launchctl unload ~/Library/LaunchAgents/com.user.macbackups.plist

# Supprimer les fichiers
rm -f ~/Library/LaunchAgents/com.user.macbackups.plist
rm -f ~/.macbackups-*.txt
rm -rf ~/logs/macbackups*
```

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :

1. Forker le projet
2. Créer une branche (`git checkout -b feature/amélioration`)
3. Commiter vos modifications (`git commit -am 'Ajout d\'une amélioration'`)
4. Pousser la branche (`git push origin feature/amélioration`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## ⚠️ Avertissements

- **Testez toujours** sur des données non critiques avant une utilisation en production
- **Vérifiez l'espace disque** disponible dans le répertoire de destination
- **Sauvegardez manuellement** les fichiers critiques avant de modifier la configuration
- Le script utilise l'option `--delete` de RSYNC qui supprime les fichiers dans la destination s'ils n'existent plus dans la source

## 📞 Support

Pour toute question ou problème :

1. Vérifiez la section [Dépannage](#-dépannage)
2. Consultez les logs dans `~/logs/`
3. Ouvrez une [Issue](https://github.com/lab34/MacBackups/issues) sur GitHub

---

**Créé avec ❤️ pour les utilisateurs macOS**