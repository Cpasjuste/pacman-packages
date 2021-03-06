cmake_minimum_required(VERSION 3.7)
include(${CMAKE_CURRENT_LIST_DIR}/devkitA64.cmake)
include(dkp-embedded-binary)

set(NX_ARCH_SETTINGS "-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -ftls-model=local-exec")
set(NX_COMMON_FLAGS  "${NX_ARCH_SETTINGS} -ffunction-sections -fdata-sections -D__SWITCH__")
set(NX_LIB_DIRS      "-L${DEVKITPRO}/libnx/lib -L${DEVKITPRO}/portlibs/switch/lib")

set(CMAKE_C_FLAGS_INIT   "${NX_COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${NX_COMMON_FLAGS}")
set(CMAKE_ASM_FLAGS_INIT "${NX_COMMON_FLAGS}")

set(CMAKE_EXE_LINKER_FLAGS_INIT "${NX_ARCH_SETTINGS} ${NX_LIB_DIRS} -fPIE -specs=${DEVKITPRO}/libnx/switch.specs")

set(CMAKE_FIND_ROOT_PATH
	${CMAKE_FIND_ROOT_PATH}
	${DEVKITPRO}/portlibs/switch
	${DEVKITPRO}/libnx
)

# Set pkg-config for the same
find_program(PKG_CONFIG_EXECUTABLE NAMES aarch64-none-elf-pkg-config HINTS "${DEVKITPRO}/portlibs/switch/bin")
if (NOT PKG_CONFIG_EXECUTABLE)
	message(WARNING "Could not find aarch64-none-elf-pkg-config: try installing switch-pkg-config")
endif()

find_program(NX_ELF2NRO_EXE NAMES elf2nro HINTS "${DEVKITPRO}/tools/bin")
if (NOT NX_ELF2NRO_EXE)
	message(WARNING "Could not find elf2nro: try installing switch-tools")
endif()

find_program(NX_NACPTOOL_EXE NAMES nacptool HINTS "${DEVKITPRO}/tools/bin")
if (NOT NX_NACPTOOL_EXE)
	message(WARNING "Could not find nacptool: try installing switch-tools")
endif()

find_file(NX_DEFAULT_ICON NAMES default_icon.jpg HINTS "${DEVKITPRO}/libnx" NO_CMAKE_FIND_ROOT_PATH)
if (NOT NX_DEFAULT_ICON)
	message(WARNING "Could not find default icon: try installing libnx")
endif()

set(NINTENDO_SWITCH TRUE)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(NX_ROOT ${DEVKITPRO}/libnx)

set(NX_STANDARD_LIBRARIES "-lnx")
set(CMAKE_C_STANDARD_LIBRARIES "${NX_STANDARD_LIBRARIES}" CACHE STRING "" FORCE)
set(CMAKE_CXX_STANDARD_LIBRARIES "${NX_STANDARD_LIBRARIES}" CACHE STRING "" FORCE)
set(CMAKE_ASM_STANDARD_LIBRARIES "${NX_STANDARD_LIBRARIES}" CACHE STRING "" FORCE)

#for some reason cmake (3.14.3) doesn't appreciate having \" here
set(NX_STANDARD_INCLUDE_DIRECTORIES "${NX_ROOT}/include")
set(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES "${NX_STANDARD_INCLUDE_DIRECTORIES}" CACHE STRING "")
set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES "${NX_STANDARD_INCLUDE_DIRECTORIES}" CACHE STRING "")
set(CMAKE_ASM_STANDARD_INCLUDE_DIRECTORIES "${NX_STANDARD_INCLUDE_DIRECTORIES}" CACHE STRING "")

function(nx_generate_nacp target)
	cmake_parse_arguments(NACP "" "NAME;AUTHOR;VERSION" "" "${ARGN}")
	if (NOT DEFINED NACP_NAME)
		set(NACP_NAME "${CMAKE_PROJECT_NAME}")
	endif()
	if (NOT DEFINED NACP_AUTHOR)
		set(NACP_AUTHOR "Unspecified Author")
	endif()
	if (NOT DEFINED NACP_VERSION)
		set(NACP_VERSION "1.0.0")
	endif()

	add_custom_command(
		OUTPUT "${target}"
		COMMAND "${NX_NACPTOOL_EXE}" --create "${NACP_NAME}" "${NACP_AUTHOR}" "${NACP_VERSION}" "${target}"
		VERBATIM
	)
endfunction()

function(nx_create_nro prefix)
	cmake_parse_arguments(ELF2NRO "NOICON;NONACP" "ICON;NACP" "" "${ARGN}")

	set(ELF2NRO_ARGS "${prefix}" "${prefix}.nro")
	set(ELF2NRO_DEPS "${prefix}")

	if (DEFINED ELF2NRO_ICON AND ELF2NRO_NOICON)
		message(FATAL_ERROR "nx_create_nro: cannot specify ICON and NOICON at the same time")
	endif()

	if (DEFINED ELF2NRO_NACP AND ELF2NRO_NONACP)
		message(FATAL_ERROR "nx_create_nro: cannot specify NACP and NONACP at the same time")
	endif()

	if (NOT DEFINED ELF2NRO_ICON AND NOT ELF2NRO_NOICON)
		set(ELF2NRO_ICON "${NX_DEFAULT_ICON}")
	endif()

	if (NOT DEFINED ELF2NRO_NACP AND NOT ELF2NRO_NONACP)
		set(ELF2NRO_NACP "${prefix}.default.nacp")
		nx_generate_nacp(${ELF2NRO_NACP})
	endif()

	if (DEFINED ELF2NRO_ICON)
		set(ELF2NRO_ARGS ${ELF2NRO_ARGS} "--icon=${ELF2NRO_ICON}")
		set(ELF2NRO_DEPS ${ELF2NRO_DEPS} "${ELF2NRO_ICON}")
	endif()

	if (DEFINED ELF2NRO_NACP)
		set(ELF2NRO_ARGS ${ELF2NRO_ARGS} "--nacp=${ELF2NRO_NACP}")
		set(ELF2NRO_DEPS ${ELF2NRO_DEPS} "${ELF2NRO_NACP}")
	endif()

	add_custom_command(
		OUTPUT "${prefix}.nro"
		COMMAND "${NX_ELF2NRO_EXE}" ${ELF2NRO_ARGS}
		DEPENDS "${prefix}" ${ELF2NRO_DEPS}
		VERBATIM
	)

	add_custom_target(
		"${prefix}_nro" ALL
		DEPENDS "${prefix}.nro"
	)
endfunction()
