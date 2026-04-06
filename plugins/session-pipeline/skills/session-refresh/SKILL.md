---
name: session-refresh
description: Jira 티켓과 연결된 Notion 문서의 컨텍스트 캐시를 강제 갱신한다. "컨텍스트 갱신", "캐시 갱신", "session-refresh" 등의 요청 시 트리거.
---

# Session Refresh — 컨텍스트 캐시 갱신

`~/.claude/memory/<티켓>/context.md` 를 삭제하고 Jira + Notion 을 MCP로 새로 조회하여 캐시를 갱신한다.

## 사용법

```
/session-refresh              # 현재 브랜치 티켓 기준
/session-refresh PROJ-123     # 특정 티켓 지정
```

## 실행 절차

### 1단계: 티켓 번호 결정

**파라미터로 티켓 번호가 주어진 경우**: 해당 티켓을 사용한다.

**파라미터가 없는 경우**: 현재 브랜치에서 파싱한다.

```bash
git rev-parse --abbrev-ref HEAD
```

- 정규식: `^([A-Z][A-Z0-9]+-[0-9]+)` 패턴을 매칭한다.
- 파싱 실패 시 사용자에게 직접 입력받는다.

### 2단계: 기존 캐시 삭제

```bash
rm -f ~/.claude/memory/<티켓>/context.md
```

파일이 없어도 에러 없이 진행한다.

### 3단계: Jira 티켓 조회

설정 파일 `~/.claude/config/session-pipeline.json`에서 `jiraCloudId`를 읽는다.
설정 파일이 없으면 사용자에게 Jira Cloud ID를 질문하고 저장한다.

`mcp__atlassian__getJiraIssue` 로 티켓을 조회한다.

```
cloudId: <설정 파일의 jiraCloudId>
issueKey: <티켓 번호>
```

조회 후 정리:
- 제목 (summary)
- 상태 (status)
- 담당자 (assignee)
- 설명 (description) 요약
- 하위 이슈 / 연결된 이슈
- description 또는 코멘트에 포함된 Notion URL 수집 (`notion.so` 또는 `notion.site` 도메인)

### 4단계: Notion 문서 조회

Notion URL이 발견되면 `mcp__notion__notion-fetch` 로 각 문서를 **병렬 조회**한다.

URL이 없으면 이 단계를 건너뛴다.

### 5단계: 캐시 파일 저장

캐시 일시는 반드시 `date +"%Y-%m-%d %H:%M:%S"` 명령 결과를 사용한다.

```
파일: ~/.claude/memory/<티켓>/context.md
```

```markdown
# 티켓 컨텍스트: <티켓번호>

- 캐시 일시: <date 명령 결과>

## Jira 티켓
- 제목: <summary>
- 상태: <status>
- 담당자: <assignee>
- 설명: <description 요약>
- 연결된 이슈: <목록>

## Notion 문서
### <문서 제목 1>
<핵심 내용 요약>
```

### 6단계: 결과 보고

```
컨텍스트 캐시 갱신 완료: <티켓번호>
- Jira: <제목> (<상태>)
- Notion: <문서 수>개 문서 로드
- 캐시: ~/.claude/memory/<티켓>/context.md
```

## 제약사항

1. **이 스킬은 context.md만 갱신한다.** 세션 기록(.md, .jsonl)은 건드리지 않는다.
2. **병렬 실행 가능한 작업은 반드시 병렬로 실행한다.**
3. **Notion URL은 Jira 티켓의 description과 코멘트에서만 추출한다.**
