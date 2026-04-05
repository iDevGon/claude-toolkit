#!/bin/bash
# Session End Hook - 세션 종료 시 transcript를 memory 디렉토리에 복사
# stdin으로 { session_id, transcript_path, cwd } JSON이 들어옴
#
# 저장 조건 (모두 충족해야 저장):
#   1. 파일 크기 >= 10KB
#   2. user 메시지 >= 3개
#   3. 코드 변경 도구(Edit, Write, NotebookEdit) 사용 >= 1회 OR user 메시지 >= 6개
#   4. 브랜치에 Jira 티켓 번호가 있어야 함
#
# 저장 경로: ~/.claude/memory/<티켓>/<레포명>/<timestamp>-raw.jsonl

HOOK_DATA=$(cat)
SESSION_ID=$(echo "$HOOK_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))")
TRANSCRIPT_PATH=$(echo "$HOOK_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transcript_path',''))")
CWD=$(echo "$HOOK_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))")

# transcript 파일이 없으면 종료
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

# 조건 1: 파일 크기 >= 10KB
FILE_SIZE=$(stat -f%z "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
if [ "$FILE_SIZE" -lt 10240 ]; then
  exit 0
fi

# 조건 2: user 메시지 >= 3개
USER_MSG_COUNT=$(grep -c '"type":"user"' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
if [ "$USER_MSG_COUNT" -lt 3 ]; then
  exit 0
fi

# 조건 3: 코드 변경 도구 사용 >= 1회 OR user 메시지 >= 6개
EDIT_COUNT=$(grep -cE '"tool_name":"(Edit|Write|NotebookEdit)"' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
if [ "$EDIT_COUNT" -lt 1 ] && [ "$USER_MSG_COUNT" -lt 6 ]; then
  exit 0
fi

# 조건 4: 브랜치에서 티켓 번호 파싱
BRANCH=$(cd "$CWD" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
TICKET=$(echo "$BRANCH" | grep -oE '^[A-Z][A-Z0-9]+-[0-9]+')

if [ -z "$TICKET" ]; then
  exit 0
fi

# 레포명 추출
REPO=$(cd "$CWD" 2>/dev/null && basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
if [ -z "$REPO" ]; then
  REPO="unknown"
fi

# 디렉토리 생성 및 복사
DEST_DIR="$HOME/.claude/memory/${TICKET}/${REPO}"
mkdir -p "$DEST_DIR"

TIMESTAMP=$(date +"%Y-%m-%d-%H_%M_%S")
cp "$TRANSCRIPT_PATH" "$DEST_DIR/${TIMESTAMP}-raw.jsonl"

exit 0
