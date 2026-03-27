#!/bin/bash

# 1. 환경 변수 설정
BACKUP_DIR="/root/outline-backup"
DATE=$(date +%Y-%m-%d-%H%M)
DB_CONTAINER="outline-docker-compose-wk-postgres-1"
DB_USER="user"   # <--- 여기에 실제 DB 사용자명을 입력하세요.
MAIN_BRANCH="latest"    # <--- GitHub의 Default 브랜치명 반영

cd $BACKUP_DIR

# 2. 로컬 저장소를 최신 'latest' 브랜치 상태로 동기화
git checkout $MAIN_BRANCH 
git pull origin $MAIN_BRANCH

# 3. 데이터 덤프 실행 (파일명을 고정하여 변경 사항 추적 가능하게 함)
# 만약 비밀번호를 물어본다면 실행 전 export PGPASSWORD='비번'을 입력하세요.
docker exec $DB_CONTAINER pg_dump -U $DB_USER outline > outline_db_backup.sql

# 4. 백업용 임시 브랜치 생성 (매번 새로 갱신)
git checkout -B auto-backup

# 5. 변경사항 커밋 및 강제 푸시
git add .
git commit -m "Outline Backup: $DATE"
git push -f origin auto-backup

# 6. GitHub CLI로 PR 생성 (Base를 latest로 지정)
# --fill: 커밋 메시지를 제목과 본문에 자동 사용
gh pr create --base $MAIN_BRANCH \
             --head auto-backup \
             --title "📅 정기 데이터 백업 ($DATE)" \
             --body "자동 생성된 백업입니다. 변경 내용을 확인 후 머지하세요." || echo "기존 PR이 이미 존재하여 브랜치만 업데이트되었습니다."
