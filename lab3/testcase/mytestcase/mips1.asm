.text
main:
    # 1. 목적지 주소들에 명령어(기계어) 미리 저장
    li $t1, 0x24110002       # li $s1, 2
    li $t0, 0x00400000
    sw $t1, 0x400($t0)           # 0x00000400에 저장
    
    li $t1, 0x24110001       # li $s1, 1
    li $t1, 0x24110001       # li $s1, 1
    li $t1, 0x24110001       # li $s1, 1
    li $t1, 0x24110001       # li $s1, 1
    li $t1, 0x24110001       # li $s1, 1
    li $t1, 0x24110001       # li $s1, 1
    
    
    li $t1, 0x24110001       # li $s1, 1
    li $t0, 0x10400000
    sw $t1, 0x400($t0)           # 0x10000400에 저장

    # 2. 임계점(0x0FFFFFFC)에 점프 명령어 저장
    li $t1, 0x08100100       # j 0x100 (Offset 0x100)
    lui $t0, 0x0FFF
    ori $t0, $t0, 0xFFFC
    sw $t1, 0($t0)           # 0x0FFFFFFC에 저장

    # 3. 운명의 실행
    jr $t0                   # 0x0FFFFFFC로 강제 진입!