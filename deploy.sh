#!/bin/bash

# Flutter 웹 빌드
flutter build web

# 현재 브랜치 저장
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# 배포 파일 임시 복사
rm -rf temp_deploy
mkdir temp_deploy
cp -r build/web/* temp_deploy/

# gh-pages 브랜치가 없다면 생성
if ! git show-ref --quiet refs/heads/gh-pages; then
  git checkout --orphan gh-pages
else
  git checkout gh-pages
fi

# 기존 파일 제거
git rm -rf . > /dev/null 2>&1

# 새 빌드 파일 복사
cp -r ../temp_deploy/* .

# 파일 커밋
git add .
git commit -m "🚀 Deploy Flutter Web to gh-pages" || echo "No changes to commit"
git push origin gh-pages

# 원래 브랜치 복귀
git checkout "$CURRENT_BRANCH"

# 임시 파일 삭제
rm -rf temp_deploy

echo ""
echo "✅ 배포 완료!"
echo "🔗 https://gwon7210.github.io/lunch_vote/"

