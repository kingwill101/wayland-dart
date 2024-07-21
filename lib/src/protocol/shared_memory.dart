import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';

final ffi.DynamicLibrary libc =
    ffi.DynamicLibrary.open(Platform.isLinux ? 'libc.so.6' : 'libc.dylib');

typedef MemfdCreateNative = ffi.Int32 Function(
    ffi.Pointer<ffi.Int8> name, ffi.Uint32 flags);
typedef MemfdCreateDart = int Function(ffi.Pointer<ffi.Int8> name, int flags);

typedef FtruncateNative = ffi.Int32 Function(ffi.Int32 fd, ffi.Int64 length);
typedef FtruncateDart = int Function(int fd, int length);

typedef MmapNative = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Void>,
    ffi.IntPtr, ffi.Int32, ffi.Int32, ffi.Int32, ffi.IntPtr);
typedef MmapDart = ffi.Pointer<ffi.Void> Function(
    ffi.Pointer<ffi.Void>, int, int, int, int, int);

typedef MunmapNative = ffi.Int32 Function(ffi.Pointer<ffi.Void>, ffi.IntPtr);
typedef MunmapDart = int Function(ffi.Pointer<ffi.Void>, int);

final MemfdCreateDart memfdCreate = libc
    .lookup<ffi.NativeFunction<MemfdCreateNative>>('memfd_create')
    .asFunction();

final FtruncateDart ftruncate =
    libc.lookup<ffi.NativeFunction<FtruncateNative>>('ftruncate').asFunction();

final MmapDart mmap =
    libc.lookup<ffi.NativeFunction<MmapNative>>('mmap').asFunction();

final MunmapDart munmap =
    libc.lookup<ffi.NativeFunction<MunmapNative>>('munmap').asFunction();

class SharedMemory {
  int _fd = -1;
  ffi.Pointer<ffi.Void>? _mappedMemory;
  int _size = 0;

  SharedMemory();

  bool create(int size) {
    final namePointer = 'wayland_shm'.toNativeUtf8().cast<ffi.Int8>();
    _fd = memfdCreate(namePointer, 0);
    calloc.free(namePointer);

    if (_fd == -1) {
      print('Failed to create memfd');
      return false;
    }

    if (ftruncate(_fd, size) == -1) {
      print('Failed to set size of memfd');
      return false;
    }

    _size = size;
    return true;
  }

  bool map() {
    if (_fd == -1 || _size == 0) {
      print('Invalid file descriptor or size');
      return false;
    }

    _mappedMemory = mmap(
      ffi.nullptr,
      _size,
      3, // PROT_READ | PROT_WRITE
      1, // MAP_SHARED
      _fd,
      0,
    );

    if (_mappedMemory == ffi.nullptr) {
      print('Failed to map memory');
      return false;
    }

    return true;
  }

  bool unmap() {
    if (_mappedMemory == null) {
      print('Memory not mapped');
      return false;
    }

    int result = munmap(_mappedMemory!, _size);
    if (result == -1) {
      print('Failed to unmap memory');
      return false;
    }

    _mappedMemory = null;
    return true;
  }

  int getFd() {
    return _fd;
  }

  ffi.Pointer<ffi.Void>? get mappedMemory => _mappedMemory;
  int get size => _size;
}
