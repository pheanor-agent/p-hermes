# 의미적 인덱싱 설계 교훈 (JOB-1209)

## GRILL 리뷰에서 발견된 문제

### 1. 임베딩 컨셉 혼재
- **문제**: 코드와 설명을 같은 컬렉션에 혼합 임베딩 → cosine similarity 간섭
- **해결**: Collection 분리 (`kernel_functions`=코드, `kernel_function_descs`=설명)
- **원칙**: 서로 다른 목적의 임베딩은 별도 컬렉션으로 분리

### 2. 대용량 함수 처리 부재
- **문제**: 커널 함수 500-1000줄 흔함, 단일 Chunk 임베딩 시 8191 토큰 초과
- **해결**: 계층적 블록 분할 (50줄 기준, 최대 80줄/블록)
- **원칙**: 실제 데이터 분포를 고려한 Chunk 크기 제한 필수

### 3. 설명 갱신 전략 부재
- **문제**: 코드 변경 시 설명 outdated 가능성
- **해결**: git diff 기반 증분 갱신 (변경된 함수만 재생성)

## 한국어 개념어 매핑

```python
KOREAN_CONCEPT_MAP = {
    "스케줄링": ["schedule", "sched", "tick", "preempt"],
    "스케줄러": ["schedule", "sched", "pick_next_task"],
    "프로세스": ["task_struct", "do_fork", "copy_process", "wake_up"],
    "태스크": ["task_struct", "task", "switch_to"],
    "컨텍스트스위치": ["context_switch", "switch_to"],
    "메모리": ["alloc", "kmalloc", "kfree", "page", "vmalloc"],
    "메모리할당": ["kmalloc", "kmalloc_calloc", "alloc_pages", "vmalloc"],
    "페이지": ["page", "pte", "pmd", "pude", "pgd"],
    "파일": ["vfs_read", "vfs_write", "vfs_open", "dentry", "inode"],
    "파일시스템": ["vfs", "dentry", "inode", "super_block"],
    "네트워크": ["sock", "sk_buff", "tcp", "udp", "inet"],
    "소켓": ["sock", "socket", "inet_create"],
    "스핀락": ["spin_lock", "spin_unlock", "spinlock_t"],
    "락": ["lock", "mutex", "rwlock", "spin_lock"],
    "시스템콜": ["sys_", "syscall", "entry_SYSCALL"],
    "인터럽트": ["irq", "handle_irq", "do_IRQ"],
    "타이머": ["hrtimer", "timer", "timer_list"],
}
```

**한계**: 하드코딩 매핑은 확장성 한계. 장기적으로 LLM 기반 동적 매핑 필요.

## Typer 다국어 인자 파싱

Shell이 띄어쓰기로 인자 분리 → Typer가 extra arguments 에러 발생.

**해결**: `main()`에서 `sys.argv` 전처리
- `kernel-chat ask 어떤 함수를 알고 있어?` → `query="어떤 함수를 알고 있어?"`
- Typer의 `allow_extra_args`는 Click 레벨 기능이며 Typer에서 올바르게 전달 안 함
- **sys.argv 전처리가 유일한 안정적 해결책**

## 비용 분석

| 항목 | 값 |
|------|-----|
| 함수 10개당 LLM 호출 | 1회 (gpt-4o-mini) |
| 1,619개 함수 기준 | ~162회 호출 |
| 1회 호출 비용 | ~$0.005 |
| 총 비용 (최초) | ~$0.81 |
| 증분 갱신 | 변경 함수 수에 비례 |
