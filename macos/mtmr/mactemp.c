// Prints the CPU temperature of an Apple Silicon Mac from the SMC, e.g. "52°", the same value
// MacFanPro shows: the TCMb key (hottest CPU core), truncated to whole degrees.
// Without TCMb it falls back to the hottest core key (Tp**: performance, Te**: efficiency;
// older chips name them Tp01, Tp05...; M1 names them Tp2a, Tp3a..., "a" being the current reading).
// "mactemp -v" lists the keys it read.
// Build: clang -O2 -framework IOKit -framework CoreFoundation mactemp.c -o mactemp

#include <IOKit/IOKitLib.h>
#include <stdio.h>
#include <string.h>

typedef struct {
  char major, minor, build, reserved;
  unsigned short release;
} SMCVersion;

typedef struct {
  unsigned short version, length;
  unsigned int cpuPLimit, gpuPLimit, memPLimit;
} SMCPLimitData;

typedef struct {
  unsigned int dataSize, dataType;
  char dataAttributes;
} SMCKeyInfo;

typedef struct {
  unsigned int key;
  SMCVersion vers;
  SMCPLimitData pLimitData;
  SMCKeyInfo keyInfo;
  char result, status, data8;
  unsigned int data32;
  unsigned char bytes[32];
} SMCKeyData;

enum { kSMCHandleYPCEvent = 2, kSMCReadKey = 5, kSMCGetKeyInfo = 9 };

static io_connect_t connection;

static unsigned int fourCC(const char *s) {
  return (unsigned int)s[0] << 24 | (unsigned int)s[1] << 16 | (unsigned int)s[2] << 8 | (unsigned int)s[3];
}

static int call(SMCKeyData *input, SMCKeyData *output) {
  size_t size = sizeof(SMCKeyData);
  return IOConnectCallStructMethod(connection, kSMCHandleYPCEvent, input, sizeof(SMCKeyData), output, &size) == kIOReturnSuccess
    && output->result == 0;
}

// Returns the key's temperature in °C, or -1 when the key does not exist or is not a float.
static double readTemperature(const char *key) {
  SMCKeyData input = {0}, output = {0};
  input.key = fourCC(key);
  input.data8 = kSMCGetKeyInfo;
  if (!call(&input, &output) || output.keyInfo.dataType != fourCC("flt ")) return -1;

  input.keyInfo.dataSize = output.keyInfo.dataSize;
  input.data8 = kSMCReadKey;
  memset(&output, 0, sizeof(output));
  if (!call(&input, &output)) return -1;

  float value;
  memcpy(&value, output.bytes, sizeof(value));
  return value > 0 && value < 150 ? value : -1;
}

int main(int argc, char **argv) {
  int verbose = argc > 1 && strcmp(argv[1], "-v") == 0;
  io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
  if (!service || IOServiceOpen(service, mach_task_self(), 0, &connection) != kIOReturnSuccess) return 1;

  double hottest = readTemperature("TCMb");
  if (verbose && hottest > 0) printf("TCMb %.1f\n", hottest);

  const char *prefixes[] = { "Tp", "Te" };
  const char *suffix = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
  double best = -1;

  for (int p = 0; hottest < 0 && p < 2; p++) {
    for (const char *a = "0123456789"; *a; a++) {
      for (const char *b = suffix; *b; b++) {
        if ((*a != '0' && *b != 'a') || strchr("bxz", *b)) continue;
        char key[5] = { prefixes[p][0], prefixes[p][1], *a, *b, 0 };
        double value = readTemperature(key);
        if (value < 0) continue;
        if (verbose) printf("%s %.1f\n", key, value);
        if (value > best) best = value;
      }
    }
  }

  if (hottest < 0) hottest = best;
  IOServiceClose(connection);
  if (hottest < 0) return 1;
  if (!verbose) printf("%d°", (int)hottest);
  return 0;
}
