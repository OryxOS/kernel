project('Oryx.Kernel', 'cpp', version: '1.0.0')

cpp_sources = files(
	'Source/Kernel.cpp',

	'Source/Init/Init.cpp',

	'Source/Common/Buffer.cpp',
	'Source/Common/Console.cpp',
	
	'Source/Arch/Amd64/Drivers/Display/VGA.cpp'
)

cpp_includes = include_directories('Source')

nasm_sources = files(
	'Source/Init/Entry/Amd64.asm'
)

nasm = find_program('nasm')
nasm_gen = generator(nasm, output: '@BASENAME@.o', arguments: ['-f', 'elf64', '@INPUT@', '-o', '@OUTPUT@'])
nasm_objects = nasm_gen.process(nasm_sources)

cpp_target_flags = [
	'--target=x86_64-pc-none-elf',
	'-ffreestanding',
	'-fno-builtin',
	'-nostdlib',
	'-nostdinc',
	'-nostdinc++',
]

cpp_warning_flags = [
	'-Wall',
	'-Wpedantic',
	'-Wextra',
	'-Werror',
	'-Wold-style-cast',
]

ld_script = meson.current_source_dir() + '/Build/Link.ld'

cpp_flags = []

cpp_flags += cpp_target_flags
cpp_flags += cpp_warning_flags
cpp_flags += ['-std=c++20']

ld_flags = [
	'-T',
	ld_script,
	'-nostdlib',
	'-mcmodel=kernel',
	'-fno-PIC',
	'-no-pie'
]

add_global_arguments(cpp_flags, language: 'cpp')
add_global_link_arguments(ld_flags, language: 'cpp')

executable('Kernel.elf', cpp_sources, nasm_objects, include_directories: cpp_includes, link_depends: ld_script)