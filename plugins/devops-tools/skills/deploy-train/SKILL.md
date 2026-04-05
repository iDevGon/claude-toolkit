---
name: deploy-train
description: 배포트레인 티켓(SD 프로젝트)을 자동 생성하는 스킬. 지라티켓, 노션, 피그마, 슬랙 등의 컨텍스트 URL을 받아 MCP로 읽고, SD 보드에 Ready To Deploy 배포 티켓을 생성한다. "배포 티켓", "배포트레인", "deploy train", "SD 티켓 생성" 등의 요청 시 트리거.
---

# Deploy Train Ticket Creator

배포해야 할 작업의 컨텍스트(지라티켓, 노션 문서, 피그마, 슬랙 등)를 파라미터로 받아 SD(서비스배포 트레인) 프로젝트에 배포 티켓을 생성한다.

## 사용법

```
/deploy-train <context URLs 또는 ticket keys...>
```

예시:
```
/deploy-train PROJ-123 https://www.notion.so/your-workspace/... https://figma.com/design/...
/deploy-train PROJ-139 PROJ-140 https://www.notion.so/your-workspace/abc123
```

## 설정 파일

실행 전 `~/.claude/config/deploy-train.json`을 읽어서 설정값을 가져온다.
설정 파일이 없으면 사용자에게 각 항목을 질문하고, 답변을 설정 파일로 저장한다.

```json
// ~/.claude/config/deploy-train.json
{
  "jiraCloudId": "<Jira Cloud ID, 예: your-org.atlassian.net>",
  "projectKey": "<배포 프로젝트 키, 예: SD>",
  "issueTypeName": "<이슈 타입명, 예: 작업>",
  "defaultAssigneeAccountId": "<기본 담당자 Jira accountId>",
  "defaultReporterAccountId": "<기본 보고자 Jira accountId>",
  "customFields": {
    "preQA": "<사전QA 커스텀필드 ID, 예: customfield_10735>",
    "preQA_DONE": "<DONE 옵션 ID, 예: 10419>",
    "preQA_BYPASS": "<BYPASS 옵션 ID, 예: 10421>",
    "assignees": "<담당자들 커스텀필드 ID, 예: customfield_10669>"
  }
}
```

이하 절차에서 모든 하드코딩 값 대신 설정 파일의 값을 사용한다.

## 실행 절차

### 1단계: 컨텍스트 수집

사용자가 제공한 URL/티켓 키를 종류별로 분류하고 MCP 도구로 **병렬 조회**한다.

| 소스 | MCP 도구 | 수집 항목 |
|------|----------|-----------|
| Jira 티켓 | `mcp__atlassian__getJiraIssue` (cloudId: `<설정 파일의 jiraCloudId>`) | summary, assignee, 관련자 |
| Notion 문서 | `mcp__notion__notion-fetch` | 기획 내용, 관련자(PO 등) |
| Figma | `mcp__figma-remote-mcp__get_metadata` | 디자인 관련자(PD) |
| Slack | 사용자 제공 텍스트에서 파악 | 추가 컨텍스트 |

### 2단계: 정보 정리 및 필수 질문

수집한 컨텍스트에서 다음을 정리한다:

- **제목(summary)**: 배포 작업을 대표하는 간결한 제목
- **관련 Jira 티켓 키 목록**: 하위 작업으로 연결할 대상
- **관련자 목록**: FE 개발자, BE 개발자, PO, PD, QA 등 모든 관련자

**아래 2가지 항목은 컨텍스트에서 명확히 판단되지 않으면 반드시 사용자에게 질문한다.**
사용자의 답변을 받기 전에는 절대로 티켓 생성을 진행하지 않는다.

1. **오전배포 / 오후배포** -> 레이블로 설정
2. **사전QA 상태: BYPASS / DONE** -> 사전QA완료 필드에 설정

질문 형식:
```
배포 티켓 생성 전 확인이 필요합니다:

1. 오전배포 / 오후배포 중 어느 것인가요?
2. 사전QA: BYPASS / DONE 중 어느 것인가요?
```

### 3단계: 관련자 Account ID 조회

담당자들 필드에 등록할 사용자들의 Jira accountId를 조회한다.

```
mcp__atlassian__lookupJiraAccountId
  cloudId: <설정 파일의 jiraCloudId>
  searchString: <사용자 이름 또는 닉네임>
```

모든 관련자를 **병렬로** 조회하여 accountId를 수집한다.

### 4단계: 티켓 생성

`mcp__atlassian__createJiraIssue` 로 티켓을 생성한다.

**고정 설정값:**

| 파라미터 | 값 |
|----------|-----|
| `cloudId` | `<설정 파일의 jiraCloudId>` |
| `projectKey` | `<설정 파일의 projectKey>` |
| `issueTypeName` | `<설정 파일의 issueTypeName>` |
| `summary` | 2단계에서 정리한 제목 |
| `assignee_account_id` | `<설정 파일의 defaultAssigneeAccountId>` |

**description은 설정하지 않는다.** 기본 템플릿이 자동 적용된다. 작업자가 직접 내용을 채워야 하는 영역이므로 절대로 AI가 작성하지 않는다.

**additional_fields:**

```json
{
  "reporter": {"accountId": "<설정 파일의 defaultReporterAccountId>"},
  "labels": ["오전배포"] 또는 ["오후배포"],
  "<설정 파일의 customFields.preQA>": [{"id": "<DONE 또는 BYPASS에 해당하는 옵션 ID>"}],
  "<설정 파일의 customFields.assignees>": [{"accountId": "..."}, {"accountId": "..."}, ...]
}
```

- `labels`: 사용자 답변에 따라 `["오전배포"]` 또는 `["오후배포"]` 설정
- `<customFields.preQA>` (사전QA완료):
  - DONE → `[{"id": "<customFields.preQA_DONE>"}]`
  - BYPASS → `[{"id": "<customFields.preQA_BYPASS>"}]`
- `<customFields.assignees>` (담당자들): 3단계에서 조회한 모든 관련자의 accountId 배열

### 5단계: 관련 Jira 티켓 연결 (연결된 업무 항목)

생성된 SD 티켓에 관련 Jira 티켓들을 **Relates** 링크로 연결한다. (연결된 업무 항목)

각 관련 티켓마다 `mcp__atlassian__createIssueLink` 를 **병렬 호출**:

```
cloudId: <설정 파일의 jiraCloudId>
type: Relates
inwardIssue: <새로 생성된 SD 티켓 키>
outwardIssue: <관련 티켓 키>
```

### 6단계: 결과 보고

생성 결과를 간결하게 보고한다:

```
<projectKey>-XX 배포 티켓이 생성되었습니다.
- URL: https://<jiraCloudId>/browse/<projectKey>-XX
- 레이블: 오전배포/오후배포
- 사전QA: DONE/BYPASS
- 담당자: <설정 파일의 담당자>
- 담당자들: [관련자 목록]
- 하위 연결 티켓: [연결된 티켓 목록]
```

## 제약사항 (절대 준수)

1. **티켓 내용(description)은 절대 작성 금지.** 기본 템플릿만 사용한다. AI가 description 필드에 어떤 값도 넣지 않는다.
2. **관련 Jira 티켓은 모두 Relates 링크로 연결 (연결된 업무 항목)한다.**
3. **담당자(assignee)는 반드시 설정 파일의 `defaultAssigneeAccountId`로 설정한다.**
4. **담당자들(`<customFields.assignees>`)에는 컨텍스트에서 파악된 모든 관련자를 등록한다.** (FE, BE, PO, PD, QA 모두 포함)
5. **보고자(reporter)도 반드시 설정 파일의 `defaultReporterAccountId`로 설정한다.**
6. **절대로 티켓의 진행상태(status/transition)를 변경하지 않는다.** transition 파라미터를 사용하지 않는다.
7. **절대로 다른 기존 티켓을 수정(edit)하지 않는다.** 이슈 링크 생성(`createIssueLink`)만 허용된다.
