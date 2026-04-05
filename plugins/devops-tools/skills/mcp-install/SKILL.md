# MCP Install
# Created by Nello

MCP 서버를 설치하는 스킬입니다. 사용법: /mcp-install [서비스명]

## 지원 서비스 목록

| 서비스명 | 설명 |
|---------|------|
| notion | Notion MCP 서버 |
| atlassian | Atlassian (Jira/Confluence) MCP 서버 |
| playwright | Playwright 브라우저 자동화 MCP 서버 |

## 설치 명령어

### notion
```bash
claude mcp add --transport http notion https://mcp.notion.com/mcp --scope user
```

### atlassian
```bash
claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse --scope user
```

### playwright
- 현재 프로젝트용:
```bash
claude mcp add playwright npx @playwright/mcp@latest
```
- 전역 설치 (모든 프로젝트용):
```bash
claude mcp add playwright -s user npx @playwright/mcp@latest
```

## 실행 흐름

1. 사용자가 `/mcp-install [서비스명]`을 입력
2. 서비스명이 지원 목록에 있는지 확인
3. 해당 서비스의 설치 명령어를 실행
4. 설치 결과를 사용자에게 안내

## 규칙

- 지원하지 않는 서비스명이 입력되면 지원 목록을 보여주고 안내
- 서비스명 없이 실행하면 지원 가능한 서비스 목록을 표시
- 설치 전 사용자에게 설치할 서비스를 확인
- 설치 완료 후 결과를 명확히 안내
