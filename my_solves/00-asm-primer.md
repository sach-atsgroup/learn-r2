# R2

## asm

writing to 8bit name does not zero top of registers, 32bit does zero first 32bits

1. rdi
2. rsi
3. rdx
4. rcx
5. r8
6. r9
7. stack

## Exercises

### 0A

```asm
0000000000001149 <triple_plus>:
    1149:       endbr64
    114d:       push   rbp                          ; save original frame pointer
    114e:       mov    rbp,rsp                      ; stack pointer to frame pointer
    1151:       mov    DWORD PTR [rbp-0x4],edi      ; first argument to stack
    1154:       mov    DWORD PTR [rbp-0x8],esi      ; second argument to stack
    1157:       mov    edx,DWORD PTR [rbp-0x4]      ; first arg to edx
    115a:       mov    eax,edx                      ; edx to eax
    115c:       add    eax,eax                      ; edx times 2 on eax
    115e:       add    edx,eax                      ; edx + eax = edx + 2 x edx
    1160:       mov    eax,DWORD PTR [rbp-0x8]      ; second arg to eax
    1163:       add    eax,edx                      ; second arg + 3x arg 1
    1165:       pop    rbp                          ; 32 bit return
    1166:       ret
```
triple_plus(a,b): return b + 3a

```sh
make check N=0a A=26
PASS 0a
```

### 0B

```asm
0000000000001167 <fork_in_road>:
    1167:       endbr64
    116b:       push   rbp
    116c:       mov    rbp,rsp
    116f:       mov    DWORD PTR [rbp-0x4],edi
    1172:       cmp    DWORD PTR [rbp-0x4],0xa
    1176:       jle    1180 <fork_in_road+0x19>     ; jump to 1180 als arg 1 < 0xA
    1178:       mov    eax,DWORD PTR [rbp-0x4]      ; arg 1 to eax
    117b:       sub    eax,0xa                      ; eax - 10
    117e:       jmp    1185 <fork_in_road+0x1e>     ; to return
    1180:       mov    eax,DWORD PTR [rbp-0x4]      ; arg 1 tp eax
    1183:       add    eax,eax                      ; eax x2
    1185:       pop    rbp
    1186:       ret
```

```c
int fork_in_road(int arg) {
    if (arg > 10) {
        return arg - 10;
    }
    return 2*arg;
}
```
```sh
make check N=0b A=15
PASS 0b
```

### 0C

0000000000001187 <sixth_arg>:
    1187:       endbr64
    118b:       push   rbp
    118c:       mov    rbp,rsp
    118f:       mov    DWORD PTR [rbp-0x4],edi
    1192:       mov    DWORD PTR [rbp-0x8],esi
    1195:       mov    DWORD PTR [rbp-0xc],edx
    1198:       mov    DWORD PTR [rbp-0x10],ecx
    119b:       mov    DWORD PTR [rbp-0x14],r8d ; #5
    119f:       mov    DWORD PTR [rbp-0x18],r9d ; #6
    11a3:       mov    eax,DWORD PTR [rbp-0x14] ; eax is r8d
    11a6:       sub    eax,DWORD PTR [rbp-0x18] ; eax -= r9d
    11a9:       pop    rbp
    11aa:       ret

```c
int sixt_arg(int one, int two, int three, int four, int five, int six) {
    return five - six;
}
```
```sh
make check N=0c A=42
PASS 0c
```

### 0D

```asm
00000000000011ab <accumulate>:
    11ab:       endbr64
    11af:       push   rbp
    11b0:       mov    rbp,rsp
    11b3:       mov    DWORD PTR [rbp-0x14],edi ; #1
    11b6:       mov    DWORD PTR [rbp-0x8],0x0  ; _0
    11bd:       mov    DWORD PTR [rbp-0x4],0x1  ; _1
    11c4:       jmp    11d3 <accumulate+0x28>   ; => 11d3
    11c6:       mov    eax,DWORD PTR [rbp-0x4]  ; eax = 2
    11c9:       imul   eax,eax                  ; 2x2
    11cc:       add    DWORD PTR [rbp-0x8],eax  ; _0 + 4
    11cf:       add    DWORD PTR [rbp-0x4],0x1  ;  + _1
    11d3:       mov    eax,DWORD PTR [rbp-0x4]  ; eax = 2
    11d6:       cmp    DWORD PTR [rbp-0x14],eax ; cmp arg 2, #eax (Starts w _1)
    11d9:       jae    11c6 <accumulate+0x1b>   ; jump >= : => 11c6
    11db:       mov    eax,DWORD PTR [rbp-0x8]
    11de:       pop    rbp
    11df:       ret
```
```c
int accumulate(int arg) {
    int i = 1;
    int j = 0;
    while (arg >= i) {
        j += i*i; // 1 + 4 + 9 + 16 = 30
        i += 1;
    }
    return j;
}
```
```sh
make check N=0d A=14
FAIL 0d - not the expected answer
make: *** [Makefile:49: check] Error 1

r2 on  solutions
####
make check N=0d A=30
PASS 0d
```