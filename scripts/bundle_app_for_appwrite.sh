#!/bin/bash
# Bundle the Flutter web app source for Appwrite Hosting deployment.
# Appwrite runs: flutter build web --dart-define-from-file=env.json
# Upload the resulting tar.gz to Appwrite Hosting > Deployments.

tar -czf ../medicortex-appwrite-final.tar.gz \
  --exclude='.git' \
  --exclude='.dart_tool' \
  --exclude='build' \
  --exclude='scripts/venv' \
  --exclude='path' \
  --exclude='android' \
  --exclude='ios' \
  --exclude='linux' \
  --exclude='macos' \
  --exclude='windows' \
  --exclude='.gradle' \
  --exclude='.DS_Store' \
  --exclude='*.tar.gz' \
  --exclude='*.zip' \
  --exclude='env.original.json' \
  --exclude='DEMO_VIDEO_SCRIPT.md' \
  --exclude='HACKATHON_PLAN.md' \
  --exclude='DEVPOST_STORY.md' \
  .

echo "✅ Bundle created: ../medicortex-appwrite-final.tar.gz"
echo "   Size: $(du -sh ../medicortex-appwrite-final.tar.gz | cut -f1)"
echo "   Files: $(tar -tzf ../medicortex-appwrite-final.tar.gz | wc -l | tr -d ' ') entries"
