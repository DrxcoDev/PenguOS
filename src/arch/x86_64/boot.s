section .multiboot
align 8
dd 0xE85250D6        ; Magic number
dd 0                 ; Architecture (0 para x86)
dd 8                 ; Longitud de la estructura
dd -(0xE85250D6 + 0 + 8) ; Checksum

section .bss
align 16
stack_bottom:
    resb 4096 * 4    ; 16 KB de stack
stack_top:

section .text
global _start
_start:
    cli              ; Desactivar interrupciones
    mov esp, stack_top ; Configurar la pila

    ; Cargar GDT
    lgdt [gdt_descriptor]

    ; Habilitar modo largo (64 bits)
    mov eax, 0xC0000080
    rdmsr
    or eax, 0x100
    wrmsr

    ; Activar paginaci�n
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Cargar CR3 con la direcci�n de la tabla de p�ginas
    mov eax, pml4_table
    mov cr3, eax

    ; Habilitar modo de paginaci�n largo
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ; Saltar al modo de 64 bits
    jmp 0x08:long_mode

section .data
gdt:
    dq 0             ; Descriptor nulo
    dq 0x00A09A0000000000 ; C�digo de 64 bits
    dq 0x00A0920000000000 ; Datos de 64 bits

gdt_descriptor:
    dw gdt_descriptor - gdt - 1
    dq gdt

align 4096
pml4_table:
    dq 0x2000 | 3    ; Primera entrada apunta a PDPT

align 4096
pdpt_table:
    dq 0x3000 | 3    ; Primera entrada apunta a PDT

align 4096
pdt_table:
    times 512 dq 0   ; P�ginas vac�as

long_mode:
    ; Aqu� ejecutamos el c�digo en 64 bits
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Llamar al kernel en C
    extern kernel_main
    call kernel_main

    hlt
