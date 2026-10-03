# Chant d’aube — build iOS

Ce dépôt contient le projet Swift/Xcode natif de Chant d’aube.

## Important

Le workflow GitHub Actions compile le projet sur un runner macOS et produit un artefact de compilation. Il désactive volontairement la signature Apple pour la première vérification.

Cela permet de vérifier que le projet Swift/Xcode compile correctement. Pour installer l’application sur un véritable iPhone ou publier sur TestFlight, il faudra ensuite configurer la signature Apple (équipe Apple, certificat et provisioning).

Le projet cible iOS 26 et utilise AlarmKit.

## GitHub Actions

Le workflow se trouve dans :

`.github/workflows/ios-build.yml`

Il peut être lancé automatiquement après un push sur `main`/`master`, ou manuellement depuis l’onglet **Actions** de GitHub.

Apple documente `xcodebuild` comme l’outil de ligne de commande permettant de compiler les projets Xcode. GitHub fournit actuellement des runners macOS hébergés, dont `macos-26`.
