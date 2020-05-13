//
// This confidential and proprietary software may be used only as
// authorised by a licensing agreement from ARM Limited
// (C) COPYRIGHT 2019 ARM Limited
// ALL RIGHTS RESERVED
// The entire notice above must be reproduced on all authorised
// copies and copies may only be made to the extent permitted
// by a licensing agreement from ARM Limited.
//

// A flatbuffer identification string is weakly defined in flatbuffers.h
// Make a global dummy definition here to avoid it being declared in each
// compilation unit which includes flatbuffers.h
namespace flatbuffers {
    volatile const char *flatbuffer_version_string = "dummy_version";
}
