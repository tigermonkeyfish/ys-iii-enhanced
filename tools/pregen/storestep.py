#!/usr/bin/env python3
"""storestep.py: the patch's second step. From the untouched Track 02 and the track the patch made (called A here), the track
with the pre-generated store (B): the store's sectors, the flag byte in both copies of the data layout, and the changed sectors'
EDC / ECC. Standard library only, Python 3.8 and later. apply.py runs it; on its own:

    python3 storestep.py --manifest FILE.store.json --store ORIGINAL.bin PATCHED.bin
    python3 storestep.py --manifest FILE.store.json --verify TRACK.bin

Nothing of the game is in this file or in the manifest. The store is computed from ORIGINAL at run time (pack17.py: the game's own
loader runs in an interpreter) and exists only inside the finished track. Nothing else is written: no work folder, and the one
temporary file (the new track, beside PATCHED, as PATCHED's name + ".store-tmp") is removed on every way out this program has
(an error, Ctrl-C, SIGTERM, SIGHUP, SIGQUIT, Ctrl-Break); a process killed outright can leave it, and the next run removes it.

Rules (the order matters):
  1. PATCHED must be exactly A (SHA-256). B: nothing to do. Anything else is refused.
  2. ORIGINAL must be the untouched track: its file's SHA-256, or, in another layout (the data without the pregap, or 2,048-byte
     sectors), the SHA-256 of its sectors' user data. Anything else is refused before the builders see it.
  3. The builders run inside a catch-all: whatever stops them is reported in one sentence, never as a traceback (a file of the
     step that is missing or does not load included).
  4. The new track is written to a temporary file, its SHA-256 compared with B's, and only then put in PATCHED's place.
A failure leaves PATCHED as it was, byte for byte. Exit status: 0 done (or already B), 2 wrong arguments, 3 the step failed.
--verify: 0 the untouched track, A or B; 3 the track could not be checked (a file that cannot be read, a file of the step that
is missing). For any other track it prints what it finds and ends with 4 or 5:
  4  this release's patched track with something else in the store's sectors that agrees with itself: no store and no flag, or a
     store the console's own checks accept (the flag in every copy, the directory's signature against the track's own code, each
     segment's sum, the block), whose directory, EDC and ECC are right;
  5  anything else: a store the console would not load, a flag without a store, a wrong EDC / ECC, or a track that differs from
     this release's patched track outside the store's sectors and the flag byte (another release's track, a changed one, or a
     layout that cannot be compared). It never says "consistent" for those.

The manifest (JSON, our own bytes and hashes only; MANIFEST_VERSION 1), made by the build that made A: release_manifest()
computes the store and B's SHA-256 from the untouched track and A, make_manifest() is for a build that already has B. Because
release_manifest() pins what this program itself makes, it ends with check_structure(): rules on the three tracks that do not
depend on the builders (which sectors differ, the flag byte, EDC / ECC, the directory, A's own code); a build that has B as a
file calls check_structure(UNTOUCHED, A, B) itself.
  {"format": "ys3-store-manifest", "version": 1,
   "track": {"bytes": the Track 02 file's length, "sector_bytes": 2352, "sector0": the file sector that is sector 0 (the pregap's
             length), "untouched_sha256": the untouched file's, "untouched_data_sha256": that of its sectors' user data from
             sector 0 to the end (optional: lets ORIGINAL be in another layout), "patched_sha256": A's, "store_sha256": B's,
             "patched_rest_sha256": that of A's file without the store's sectors (the same for B once its flag bytes are put
             back to 0: lets --verify tell a track that differs from this release's outside the store)},
   "store": {"builder": "room17", "version": the directory's version byte (pack17.VERSION), "key": the build's key (1-65535),
             "code": {"card": the card address of our code's segment, "base64": its bytes, "sha256": their SHA-256} or null,
             "directory_sector": PGDIR, "sectors": the store's sectors with its directory,
             "flag": {"sectors": [the two sectors], "offset": the byte of its 2,048 data bytes, 0 on A and 1 on B},
             "free_run": {"sector": first, "count": sectors} the run the store must stay inside,
             "notice": what a player misses without the store, as the end of a sentence (optional)}}
"""
import base64
import hashlib
import json
import os
import stat
import sys

sys.dont_write_bytecode = True                      # nothing is left beside a player's files, not even __pycache__
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:                            # the builders are beside this file
    sys.path.insert(0, HERE)

RAW, USER = 2352, 2048
SYNC = b"\x00" + b"\xff" * 10 + b"\x00"
FORMAT, MANIFEST_VERSION = "ys3-store-manifest", 1
OK, BAD_ARGS, FAILED, SELF_CONSISTENT, INCONSISTENT = 0, 2, 3, 4, 5
NOTICE = "the quarry's bridge and shaft 19 will use their fallback pictures"
BUILDERS = ("room17",)
MAGIC = b"Y3PG"                                    # the store's signature: our own four letters, then the version byte and the key
BLOCK = 0x180000                                    # room17: the card address of the segment the loader compares at each visit
TMP = ".store-tmp"                                  # the temporary file's suffix
STOP_SIGNALS = ("SIGTERM", "SIGHUP", "SIGQUIT", "SIGBREAK")    # handled as Ctrl-C is (the ones this system has)


class StepError(Exception):
    """the step cannot be done; str() is the reason, as part of a sentence"""


def _mod(name):
    """one of the step's own modules (the builders, beside this file). A file that is missing or does not load is a StepError
    that names it, never an ImportError on its way to a traceback."""
    try:
        return __import__(name)
    except ImportError as e:
        raise StepError(f"the step's own file {getattr(e, 'name', None) or name}.py is missing or does not load: the release's files are not all here (unzip it again)")
    except RecursionError:
        raise
    except Exception as e:                              # a file cut short by an unfinished download or unzip: SyntaxError and the like
        f, tb = getattr(e, "filename", None), e.__traceback__
        while f is None and tb is not None:                 # (the file that stopped: the innermost of ours)
            if os.path.dirname(tb.tb_frame.f_code.co_filename) == HERE and not tb.tb_frame.f_code.co_filename.endswith("storestep.py"):
                name = os.path.basename(tb.tb_frame.f_code.co_filename)[:-3]
            tb = tb.tb_next
        raise StepError(f"the step's own file {os.path.basename(str(f or name + '.py'))} does not load ({type(e).__name__}): the release's files are damaged (unzip it again)")


def _hex64(x):
    return isinstance(x, str) and len(x) == 64 and all(c in ("0123456789" + "abcdef") for c in x)


def _int(x, lo, hi):
    return isinstance(x, int) and not isinstance(x, bool) and lo <= x <= hi


def check_manifest(m):
    """the manifest's shape and ranges; returns it, with the code's bytes decoded as m["store"]["code"]["bytes"]"""
    def bad(why):
        return StepError(f"the store manifest is not usable ({why})")
    if not isinstance(m, dict) or m.get("format") != FORMAT:
        raise bad("not a store manifest")
    if m.get("version") != MANIFEST_VERSION:
        raise bad(f"its version is {m.get('version')!r}, this program reads version {MANIFEST_VERSION}: the files are not of one release")
    t, s = m.get("track"), m.get("store")
    if not isinstance(t, dict) or not isinstance(s, dict):
        raise bad("no track or no store in it")
    if t.get("sector_bytes") != RAW or not _int(t.get("bytes"), RAW, 1 << 40) or t["bytes"] % RAW or not _int(t.get("sector0"), 0, t["bytes"] // RAW - 1):
        raise bad("the track's size")
    for k in ("untouched_sha256", "patched_sha256", "store_sha256", "patched_rest_sha256"):
        if not _hex64(t.get(k)):
            raise bad(k)
    if len({t["untouched_sha256"], t["patched_sha256"], t["store_sha256"]}) != 3:
        raise bad("two of its three tracks are the same")
    if "untouched_data_sha256" in t and not _hex64(t["untouched_data_sha256"]):
        raise bad("untouched_data_sha256")
    if s.get("builder") not in BUILDERS:
        raise bad(f"its store is made by {s.get('builder')!r}, which this program does not have: the files are not of one release")
    pack17 = _mod("pack17")
    if s.get("version") != pack17.VERSION:
        raise bad(f"its store is version {s.get('version')!r}, this program makes version {pack17.VERSION}: the files are not of one release")
    if not _int(s.get("key"), 1, 0xFFFF):
        raise bad("the key")
    data = t["bytes"] // RAW - t["sector0"]                 # the data sectors in the file
    fr, fl = s.get("free_run"), s.get("flag")
    if not isinstance(fr, dict) or not _int(fr.get("sector"), 0, data) or not _int(fr.get("count"), 1, data):
        raise bad("the free run")
    if s.get("directory_sector") == fr["sector"]:           # (the run's first sector is the loader's at the earliest: mkdisc)
        raise bad("the store's directory is in the sector of the store's own loader, the first of the free run")
    if not _int(s.get("directory_sector"), fr["sector"] + 1, data) or not _int(s.get("sectors"), 2, 1 << 16) \
            or s["directory_sector"] + s["sectors"] > min(fr["sector"] + fr["count"], data):
        raise bad("the store's sectors are not inside the free run")
    if not isinstance(fl, dict) or not isinstance(fl.get("sectors"), list) or not fl["sectors"] or not _int(fl.get("offset"), 0, USER - 1) \
            or not all(_int(x, 0, data - 1) for x in fl["sectors"]) or len(set(fl["sectors"])) != len(fl["sectors"]) \
            or any(s["directory_sector"] <= x < s["directory_sector"] + s["sectors"] for x in fl["sectors"]):
        raise bad("the flag byte's places")
    c = s.get("code")
    if c is not None:
        try:
            raw = base64.b64decode(c["base64"], validate=True)
            ok = _int(c["card"], 0, 0xFFFFFF) and hashlib.sha256(raw).hexdigest() == c["sha256"] and 0 < len(raw) <= 0x10000
        except Exception:
            ok = False
        if not ok:
            raise bad("the code segment")
        c["bytes"] = raw
    if "notice" in s and not (isinstance(s["notice"], str) and 0 < len(s["notice"]) < 200 and s["notice"].isprintable()):
        raise bad("the notice")
    return m


def load_manifest(path):
    try:
        with open(path, "rb") as f:
            m = json.loads(f.read().decode("utf-8"))
    except (OSError, ValueError) as e:
        raise StepError(f"the store manifest could not be read ({type(e).__name__})")
    return check_manifest(m)


def make_manifest(track_bytes, sector0, untouched_sha256, patched_sha256, store_sha256, key, code, directory_sector, sectors,
                  flag_sectors, flag_offset, free_run, untouched_data_sha256=None, notice=None, builder="room17", patched_rest_sha256=None):
    """the manifest as a dict (write it with dump_manifest). code: (card address, bytes) of our code's segment, as mkdisc gives it
    to pack17.pack, or None. free_run: (first sector, count), src/modules.json's free_runs.pregen_store. patched_rest_sha256:
    rest_sha256(A) (required). Checked before it is returned, so a build cannot write one this program would refuse. This only
    writes down what it is given: a build that uses it calls check_structure(UNTOUCHED, A, B, manifest) on its three tracks."""
    pack17 = _mod("pack17")
    m = {"format": FORMAT, "version": MANIFEST_VERSION,
         "track": {"bytes": track_bytes, "sector_bytes": RAW, "sector0": sector0, "untouched_sha256": untouched_sha256,
                   "patched_sha256": patched_sha256, "store_sha256": store_sha256, "patched_rest_sha256": patched_rest_sha256},
         "store": {"builder": builder, "version": pack17.VERSION, "key": key,
                   "code": None if code is None else {"card": code[0], "base64": base64.b64encode(bytes(code[1])).decode("ascii"),
                                                      "sha256": hashlib.sha256(bytes(code[1])).hexdigest()},
                   "directory_sector": directory_sector, "sectors": sectors,
                   "flag": {"sectors": list(flag_sectors), "offset": flag_offset},
                   "free_run": {"sector": free_run[0], "count": free_run[1]}}}
    if untouched_data_sha256:
        m["track"]["untouched_data_sha256"] = untouched_data_sha256
    if notice:
        m["store"]["notice"] = notice
    check_manifest(json.loads(json.dumps(m)))
    return m


def release_manifest(original, patched, key, code, directory_sector, flag_sectors, flag_offset, free_run, notice=None, builder="room17"):
    """a release build's call, once it has made A (PATCHED) from the untouched track (ORIGINAL, the Track 02 file as the dump has
    it): the store is computed here, B's SHA-256 is that of A with the store's sectors and the flag bytes (no track is written),
    and the manifest that pins all of it is returned. Arguments as make_manifest's.
    B is what this program makes, so the pin is only as good as this program: before the manifest is returned, check_structure()
    must pass on ORIGINAL, A and the new sectors, with the manifest's own values (a StepError otherwise, and no manifest)."""
    tr = open_track(original)
    if tr is None:
        raise StepError(f"{os.path.basename(str(original))} is not this game's data track")
    try:
        sector0, data_sha = tr.base, data_sha256(tr)
    finally:
        tr.close()
    draft = {"track": {"sector0": sector0},
             "store": {"key": key, "code": None if code is None else {"card": code[0], "bytes": bytes(code[1])}, "sectors": None,
                       "directory_sector": directory_sector, "flag": {"sectors": list(flag_sectors), "offset": flag_offset}}}
    blob = build_store(original, draft, pinned=False)
    draft["store"]["sectors"] = len(blob) // USER
    new = new_sectors(patched, blob, draft)
    m = make_manifest(os.path.getsize(original), sector0, file_sha256(original), file_sha256(patched), _stream(patched, new), key, code,
                      directory_sector, len(blob) // USER, flag_sectors, flag_offset, free_run, data_sha, notice, builder, rest_sha256(patched, draft))
    check_structure(original, patched, new, m)
    return m


def dump_manifest(m):
    """the manifest's text: the same bytes for the same manifest"""
    m = json.loads(json.dumps(m, default=lambda o: None))
    if m["store"].get("code"):
        m["store"]["code"].pop("bytes", None)
    return json.dumps(m, indent=1, sort_keys=True) + "\n"


def notice_of(m):
    return (m or {}).get("store", {}).get("notice") or NOTICE


def file_sha256(path):
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            while True:
                b = f.read(1 << 20)
                if not b:
                    break
                h.update(b)
    except OSError as e:
        raise StepError(f"{os.path.basename(str(path))} could not be read ({e.strerror or type(e).__name__})")
    return h.hexdigest()


def data_sha256(track):
    """SHA-256 of every whole sector's user data, from sector 0 to the file's end (a pce.Track): the same for the file with
    its pregap, the data alone, and a 2,048-byte-sector image"""
    h = hashlib.sha256()
    n = track.count - track.base
    for k in range(0, n, 64):
        h.update(track.sectors(k, min(64, n - k)))
    return h.hexdigest()


def open_track(path):
    """a pce.Track that reads the file's sectors as asked, or None when the file has no boot record of this game"""
    extract17, pce = _mod("extract17"), _mod("pce")
    try:
        return pce.Track(path, extract17.IPL_SHA, lazy=True)
    except ValueError:
        return None
    except OSError as e:
        raise StepError(f"{os.path.basename(str(path))} could not be read ({e.strerror or type(e).__name__})")


def _has_sync(path):
    """whether one of the file's first 400 2,352-byte sectors starts with a data sector's sync pattern"""
    try:
        with open(path, "rb") as f:
            for k in range(400):
                f.seek(k * RAW)
                b = f.read(12)
                if len(b) < 12:
                    break
                if b == SYNC:
                    return True
    except OSError:
        pass
    return False


def check_original(path, m):
    """rule 2: the untouched track, or the step stops with the reason"""
    t, name = m["track"], os.path.basename(str(path))
    h = file_sha256(path)
    if h == t["untouched_sha256"]:
        return
    if h in (t["patched_sha256"], t["store_sha256"]):
        raise StepError(f"{name} is a patched track, and this step needs the untouched one (the file kept as *.orig when the patch was applied)")
    size = os.path.getsize(path)
    if size == 0:
        raise StepError(f"{name} is empty")
    if size % RAW and _has_sync(path):                      # 2,352-byte sectors, and the file stops inside one (or has bytes too many)
        raise StepError(f"{name} is not a whole copy of the data track: its length ({size:,} bytes) is not a whole number of 2,352-byte "
                        f"sectors (the dump's Track 02 has {t['bytes']:,} bytes): an unfinished or damaged copy")
    tr = open_track(path)
    if tr is None:
        raise StepError(f"{name} is not this game's data track (it has no boot record: an audio track, or another file)")
    try:
        want = t["bytes"] // RAW - t["sector0"]
        have = tr.count - tr.base
        if have == want and t.get("untouched_data_sha256") and data_sha256(tr) == t["untouched_data_sha256"]:
            return                                          # the same data in another layout
    finally:
        tr.close()
    if have < want:
        raise StepError(f"{name} is incomplete ({have:,} of {want:,} sectors): not a whole copy of the data track")
    raise StepError(f"{name} is not the dump this patch was made for (sha256 mismatch)")


def build_store(original, m, pinned=True):
    """rule 3: the store's sectors from the untouched track, every failure as a StepError. pinned: ORIGINAL has passed rule 2 (a
    refusal by the builders is then the fault of the release's files, not of the player's track)."""
    pack17, store17 = _mod("pack17"), _mod("store17")
    s = m["store"]
    tr = open_track(original)
    if tr is None:
        raise StepError(f"{os.path.basename(str(original))} is not this game's data track")
    quiet = lambda _line: None                              # noqa: E731
    try:
        code = (s["code"]["card"], s["code"]["bytes"]) if s.get("code") else None
        blob, _info = pack17.pack(tr, None, s["key"], log=quiet, code=code, xlog=quiet)
    except store17.Refusal as e:
        if pinned:
            raise StepError(f"the step's own files do not fit this release: its builders refused the untouched track ({e}); the files are not of one release")
        raise StepError(f"the builders refused the track's data ({e})")
    except MemoryError:
        raise StepError("not enough memory")
    except (AttributeError, NameError, ImportError, SyntaxError) as e:    # a file of the step that loaded, but not whole
        raise StepError(f"the step's own program stopped ({type(e).__name__}: {str(e)[:120]}): its files are damaged or not of one release (unzip it again)")
    except (Exception, SystemExit) as e:
        raise StepError(f"the step's own program stopped ({type(e).__name__}: {str(e)[:120]})")
    finally:
        tr.close()
    if s.get("sectors") is not None and len(blob) != s["sectors"] * USER:
        raise StepError(f"the store came out as {len(blob) // USER} sectors, the release's is {s['sectors']}: the files are not of one release")
    return blob


_EDC = []


def edc130():
    """edc130.py, beside this file or one folder up (loaded by its file's name: that folder is not put on the import path)"""
    if not _EDC:
        import importlib.util
        for d in (HERE, os.path.dirname(HERE)):
            p = os.path.join(d, "edc130.py")
            if os.path.exists(p):
                try:
                    spec = importlib.util.spec_from_file_location("edc130", p)
                    mod = importlib.util.module_from_spec(spec)
                    spec.loader.exec_module(mod)
                except RecursionError:
                    raise
                except Exception as e:
                    raise StepError(f"the step's own file edc130.py does not load ({type(e).__name__}): the release's files are damaged (unzip it again)")
                _EDC.append(mod)
                break
        else:
            raise StepError("the step's own file edc130.py is missing: the release's files are not all here (unzip it again)")
    return _EDC[0]


def _seal(sec):
    edc130().seal_mode1(sec)
    return bytes(sec)


def new_sectors(patched, blob, m):
    """{file sector: its 2,352 bytes on B} for the store's sectors and the flag sectors, from A's file"""
    t, s = m["track"], m["store"]
    out = {}
    with open(patched, "rb") as f:
        def raw(sector):
            f.seek((t["sector0"] + sector) * RAW)
            b = bytearray(f.read(RAW))
            if len(b) != RAW or b[:12] != SYNC or b[15] != 1:
                raise StepError(f"sector {sector} of the patched track is not a data sector")
            return b
        for i in range(s["sectors"]):
            b = raw(s["directory_sector"] + i)
            b[16:16 + USER] = blob[i * USER:(i + 1) * USER]
            out[t["sector0"] + s["directory_sector"] + i] = _seal(b)
        for sector in s["flag"]["sectors"]:
            b = raw(sector)
            if b[16 + s["flag"]["offset"]] != 0:
                raise StepError("the patched track's flag byte is already set")
            b[16 + s["flag"]["offset"]] = 1
            out[t["sector0"] + sector] = _seal(b)
    return out


def _stream(patched, new, out=None):
    """PATCHED with the sectors of `new`: its SHA-256; written to the open file `out` when given"""
    h = hashlib.sha256()
    with open(patched, "rb") as f:
        at = 0
        while True:
            chunk = f.read(RAW * 256)
            if not chunk:
                break
            n = -(-len(chunk) // RAW)
            hit = [k for k in range(at, at + n) if k in new]
            if hit:
                chunk = bytearray(chunk)
                for k in hit:
                    chunk[(k - at) * RAW:(k - at + 1) * RAW] = new[k]
            h.update(chunk)
            if out is not None:
                out.write(chunk)
            at += n
    return h.hexdigest()


def _remove(path):
    """one of our own temporary files goes; never an error of its own"""
    try:
        os.remove(path)
    except OSError:
        try:                                                # (Windows refuses to remove a file marked read-only)
            os.chmod(path, stat.S_IWRITE | stat.S_IREAD)
            os.remove(path)
        except OSError:
            pass


def write_checked(patched, new, want_sha256):
    """rule 4: PATCHED with the sectors of `new` in a temporary file beside it; in PATCHED's place only if its SHA-256 is the one
    wanted. The temporary file never outlives this call.
    Windows (by reading, not run there): it refuses to replace a file marked read-only, and to remove one. So there the temporary
    file stays writable until it is in place, PATCHED's mark is lifted for the replace and put back on the new track (or on the
    old one, when the replace fails). Elsewhere the temporary file gets PATCHED's mode first, as before."""
    tmp = str(patched) + TMP
    done = False
    try:
        with open(tmp, "wb") as o:
            got = _stream(patched, new, o)
            o.flush()
            os.fsync(o.fileno())
        if got != want_sha256:
            raise StepError("the finished track is not the one this release makes (sha256 mismatch): the files are not of one release")
        try:
            mode = os.stat(patched).st_mode & 0o7777
        except OSError:
            mode = None
        if os.name != "nt":
            if mode is not None:
                try:
                    os.chmod(tmp, mode)
                except OSError:
                    pass
            os.replace(tmp, patched)
            done = True
        else:
            locked = mode is not None and not mode & stat.S_IWRITE
            if locked:
                os.chmod(patched, mode | stat.S_IWRITE)
            try:
                os.replace(tmp, patched)
                done = True
            finally:
                if locked:
                    try:
                        os.chmod(patched, mode)
                    except OSError:
                        pass
    except OSError as e:
        raise StepError(f"the new track could not be written ({e.strerror or type(e).__name__})")
    finally:
        if not done:
            _remove(tmp)


def add_store(original, patched, m):
    """the step. Returns "done", or "already" when PATCHED is B; raises StepError and leaves PATCHED as it was otherwise."""
    t, name = m["track"], os.path.basename(str(patched))
    patched = os.path.realpath(str(patched))
    try:
        if os.path.isfile(patched + TMP):                   # what a run that was killed outright left: never there for good
            _remove(patched + TMP)
        h = file_sha256(patched)                            # rule 1
        if h == t["store_sha256"]:
            return "already"
        if h == t["untouched_sha256"]:
            raise StepError(f"{name} is the untouched track: apply the patch to it first")
        if h != t["patched_sha256"]:
            raise StepError(f"{name} is not the track this release's patch makes (sha256 mismatch)")
        check_original(original, m)
        blob = build_store(original, m)
        write_checked(patched, new_sectors(patched, blob, m), t["store_sha256"])
    except KeyboardInterrupt:
        raise StepError("interrupted")
    except RecursionError:
        raise StepError("the step's own program stopped (RecursionError)")
    except MemoryError:
        raise StepError("not enough memory")
    except OSError as e:
        raise StepError(f"a file could not be read or written ({e.strerror or type(e).__name__})")
    return "done"


# ---------------------------------------------------------------- the rules that do not depend on the builders
def code_signature(user):
    """(version, key) from a sector of our own code that holds the store's signature (MAGIC, the version byte, the key: the
    preload's table in each of its copies, the loader's in its sector), or None when the sector does not hold it exactly once"""
    i = user.find(MAGIC)
    if i < 0 or i + 7 > len(user) or user.find(MAGIC, i + 1) >= 0:
        return None
    return user[i + 4], user[i + 5] | user[i + 6] << 8


def reads_directory(user, sector):
    """whether a sector of the preload's code names `sector` as the one it reads the store's directory from: the operands of its
    LDA # / LDX # / LDY #1 before the read (syscard_halt.asm, .pgl), exactly once"""
    return 0 <= sector < 1 << 16 and user.count(bytes((0xA9, sector & 255, 0xA2, sector >> 8, 0xA0, 1))) == 1  # own: HuC6280 LDA # / LDX # / LDY #1 opcodes in our syscard_halt.asm


def console_sum(data):
    """the 16-bit sum the console takes of a segment read back from the card (syscard_halt.asm, .sp): per 256-byte page the bytes
    added with the carry going round, the page sums folded. Written from the console's code, not from pack17.fold_sum: a page's
    end-around sum is 0 for a page of zeros and otherwise its plain sum brought into 1-255."""
    lo = hi = 0
    for p in range(0, len(data), 256):
        t = sum(data[p:p + 256])
        lo = (lo + (t and (t - 1) % 255 + 1)) & 255
        hi = (hi + lo) & 255
    return lo | hi << 8


def console_refusal(user, directory_sector, signature):
    """the console's own checks of a store (syscard_halt.asm .pgl at power-on; the loader's compare of the block at each visit,
    quarry_pgfast.inc): None when it would load the store at directory_sector, else why not. user(sector, count): user data
    (ValueError past the end). signature: (version, key) as the track's own code holds them, or None."""
    if signature is None:
        return "the track's own code holds no one signature to compare the directory with"
    want = MAGIC + bytes((signature[0], signature[1] & 255, signature[1] >> 8))
    try:
        d = user(directory_sector, 1)
    except ValueError:
        return "the directory is past the end of the track"
    if d[:4] != MAGIC:
        return "no directory"
    if d[:7] != want:
        return (f"the directory has version {d[4]} and key ${d[5] | d[6] << 8:04X}, the track's own code compares it with version "
                f"{signature[0]} and key ${signature[1]:04X}")
    if not 1 <= d[7] <= 16:
        return f"the directory names {d[7]} segments"
    at, block = directory_sector + 1, False
    for i in range(d[7]):
        e = d[8 + 8 * i:16 + 8 * i]
        if not e[3]:
            return f"segment {i} has no sectors"
        try:
            seg = user(at, e[3])
        except ValueError:
            return f"segment {i} runs past the end of the track"
        if console_sum(seg) != e[4] | e[5] << 8:
            return f"segment {i}'s sum is not the directory's"
        if int.from_bytes(e[0:3], "little") == BLOCK:
            block = True
            if seg[:7] != want:
                return "the store's block does not carry the signature the loader compares at each visit"
        at += e[3]
    if not block:
        return f"no segment is the block at card address ${BLOCK:06X}"
    return None


def rest_sha256(path, m):
    """SHA-256 of a track file (2,352-byte sectors, the manifest's layout) without the store's sectors, each flag sector with its
    flag byte as 0 and re-encoded: the same for A, for B, and for any track that differs from them only in the store's sectors,
    the flag byte and the flag sectors' own EDC / ECC. m: the manifest (its sector0, directory_sector, sectors, flag)."""
    s, s0 = m["store"], m["track"]["sector0"]
    lo = s0 + s["directory_sector"]
    hi = lo + s["sectors"]
    flags = {s0 + x for x in s["flag"]["sectors"]}
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            k = 0
            while True:
                b = f.read(RAW)
                if not b:
                    break
                if k in flags and len(b) == RAW:
                    b = bytearray(b)
                    b[16 + s["flag"]["offset"]] = 0
                    b = _seal(b)
                if not lo <= k < hi:
                    h.update(b)
                k += 1
    except OSError as e:
        raise StepError(f"{os.path.basename(str(path))} could not be read ({e.strerror or type(e).__name__})")
    return h.hexdigest()


def check_structure(original, patched, store, m=None):
    """B against A and the untouched track, by rules that do not depend on the builders being right. original, patched: the
    untouched Track 02 and A (files; 2,352-byte sectors, one layout). store: B's file, or the {file sector: 2,352 bytes} that
    new_sectors() made (B is then A with those). m: a manifest (as check_manifest returns it) whose values must also agree,
    or None: everything is taken from the three tracks. A StepError names the first rule that does not hold:
      - the three tracks have one length, a whole number of sectors;
      - A's own code (the sectors the patch changed) holds the store's signature, one version and one key, in the loader's sector
        and in every copy of the preload; each copy of the preload reads its directory from the sector after the loader's;
      - B differs from A in exactly the store's sectors (the directory's sector and the data sectors it counts) and the sectors
        of the preload's copies; no other sector, inside or outside the free run, before or after sector 0;
      - in each copy's sector exactly one byte differs, a user byte, the same one in every copy, 0 on A and 1 on B;
      - every differing sector of B is a data sector with A's address and equals a fresh EDC / ECC encode; A's flag sectors too;
      - the store's sectors are sectors the patch left as the untouched track has them (it overwrites nothing of ours);
      - the console's own checks accept the store against A's code (console_refusal), and the directory's count, lengths,
        SHA-256 values and padding hold (pack17.check);
      - with m: its lengths, sector 0, key, version, directory sector, sector count, flag sectors and offset are the ones found;
        the store and the loader's sector are inside its free run; its four (five) SHA-256 values are the tracks'.
    Returns what it found: sector0, version, key, loader_sector, directory_sector, sectors, flag_sectors, flag_offset, the
    SHA-256 of the three tracks (untouched_sha256, patched_sha256, store_sha256) and patched_rest_sha256."""
    def bad(why):
        return StepError(f"the track with the store is not the patched track plus the store ({why})")
    pack17 = _mod("pack17")
    names = [os.path.basename(str(x)) for x in (original, patched)]
    virtual = isinstance(store, dict)
    tr = open_track(original)
    if tr is None:
        raise bad(f"{names[0]} is not this game's data track")
    try:
        if not tr.raw or tr.len % RAW:
            raise bad(f"{names[0]} is not in 2,352-byte sectors")
        s0, count, data_sha = tr.base, tr.len // RAW, data_sha256(tr) if m and m["track"].get("untouched_data_sha256") else None
    finally:
        tr.close()
    files = []
    try:
        for x in (original, patched) + (() if virtual else (store,)):
            try:
                files.append(open(x, "rb"))
                if files[-1].seek(0, 2) != count * RAW:
                    raise bad(f"{os.path.basename(str(x))} has another length than {names[0]}")
                files[-1].seek(0)
            except OSError as e:
                raise bad(f"{os.path.basename(str(x))} could not be read ({e.strerror or type(e).__name__})")
        fu, fa = files[0], files[1]
        if virtual and not all(_int(k, 0, count - 1) and isinstance(v, (bytes, bytearray)) and len(v) == RAW for k, v in store.items()):
            raise bad("a new sector is outside the track or not 2,352 bytes")
        hu, ha, hb = hashlib.sha256(), hashlib.sha256(), hashlib.sha256()
        ours, diff = {}, {}                                 # file sector: A's bytes where the patch changed the track; (A's, B's) where B differs
        for at in range(0, count, 256):
            n = min(256, count - at)
            cu, ca = fu.read(n * RAW), fa.read(n * RAW)
            if virtual:
                cb = ca
                hit = [k for k in range(at, at + n) if k in store]
                if hit:
                    cb = bytearray(ca)
                    for k in hit:
                        cb[(k - at) * RAW:(k - at + 1) * RAW] = store[k]
                    cb = bytes(cb)
            else:
                cb = files[2].read(n * RAW)
            hu.update(cu)
            ha.update(ca)
            hb.update(cb)
            for c, into in ((cu, ours), (cb, diff)):
                if c != ca:
                    for k in range(n):
                        x, y = ca[k * RAW:(k + 1) * RAW], c[k * RAW:(k + 1) * RAW]
                        if x != y:
                            into[at + k] = x if into is ours else (x, y)
            if len(diff) > 1 << 12 or len(ours) > 1 << 12:
                raise bad("the tracks differ in thousands of sectors: not one release's three tracks")

        def rawb(k):                                        # B's file sector k
            if k in diff:
                return diff[k][1]
            fa.seek(k * RAW)
            return fa.read(RAW)

        def userb(sector, n):
            if sector < 0 or s0 + sector + n > count:
                raise ValueError("past the end of the track")
            return b"".join(rawb(s0 + sector + i)[16:16 + USER] for i in range(n))

        # A's own code: the signature, the loader's sector, the preload's copies
        sig = {k - s0: code_signature(x[16:16 + USER]) for k, x in ours.items() if k >= s0 and MAGIC in x[16:16 + USER]}
        if not sig:
            raise bad("the patched track's own code holds no store signature: this patch has no store loader")
        if None in sig.values() or len(set(sig.values())) != 1:
            raise bad("the patched track's own code holds the store's signature with more than one version or key (sectors "
                      + ", ".join(str(k) for k in sorted(sig)) + ")")
        version, key = next(iter(sig.values()))
        loaders = [k for k in sig if len(sig) > 1 and all(reads_directory(ours[s0 + o][16:16 + USER], k + 1) for o in sig if o != k)]
        if len(loaders) != 1:
            raise bad("the patched track's own code does not name one directory sector: the sector after the loader's must be the one "
                      "every copy of the preload reads (signature in sectors " + ", ".join(str(k) for k in sorted(sig)) + ")")
        loader = loaders[0]
        pgdir = loader + 1
        copies = sorted(k for k in sig if k != loader)
        why = console_refusal(userb, pgdir, (version, key))
        if why:
            raise bad(f"the console would not load the store: {why}")
        d = pack17.check(userb, pgdir)
        if not (d and d["count_ok"] and d["data_sha256_ok"] and all(x["sha256_ok"] and x["sum_ok"] and x["padding_ok"] for x in d["segments"])):
            raise bad("the store does not agree with its own directory (its count, a length, a SHA-256, a sum or a segment's padding)")
        run = range(pgdir, pgdir + 1 + d["data_sectors"])
        fr = m["store"]["free_run"] if m else None

        def where(k):                                       # a sector that should not differ, for the message
            if k < 0:
                return f"file sector {k + s0}, before sector 0"
            if fr and fr["sector"] <= k < fr["sector"] + fr["count"]:
                return f"sector {k}, inside the free run but outside the store"
            return f"sector {k}, outside the store" + (" and outside the free run" if fr else "")
        changed = {k - s0 for k in diff}
        extra = sorted(changed - set(run) - set(copies))
        if extra:
            raise bad(f"{len(extra)} sector(s) differ that are neither the store's nor the flag's: " + "; ".join(where(k) for k in extra[:6]))
        for k in copies:
            if k not in changed:
                raise bad(f"the flag is not set in every copy of the preload (sector {k} is as on the patched track)")
        same = [k for k in run if k not in changed]
        if same:
            raise bad(f"{len(same)} of the store's sectors are as on the patched track (sector {same[0]})")
        offsets = set()
        for k in copies:
            x, y = diff[s0 + k]
            at = [i for i in range(16 + USER) if x[i] != y[i]]
            if len(at) != 1 or at[0] < 16 or x[at[0]] != 0 or y[at[0]] != 1:
                raise bad(f"flag sector {k} differs in more than the one flag byte, 0 on the patched track and 1 with the store")
            offsets.add(at[0] - 16)
            if _seal(bytearray(x)) != x:
                raise bad(f"flag sector {k} of the patched track does not equal a fresh EDC / ECC encode")
        if len(offsets) != 1:
            raise bad("the flag byte is not the same byte in every copy of the preload")
        for k in sorted(changed):
            x, y = diff[s0 + k]
            if y[:12] != SYNC or y[15] != 1 or y[12:16] != x[12:16]:
                raise bad(f"sector {k} is not a data sector with the patched track's address")
            if _seal(bytearray(y)) != y:
                raise bad(f"sector {k}'s EDC / ECC does not equal a fresh encode")
        used = [k for k in run if s0 + k in ours]
        if used:
            raise bad(f"the store overwrites sectors the patch itself wrote (sector {used[0]}): they are not free")
        rest = hashlib.sha256()
        fa.seek(0)
        for k in range(count):
            x = fa.read(RAW)
            if k - s0 not in run:
                rest.update(x)
        found = dict(sector0=s0, version=version, key=key, loader_sector=loader, directory_sector=pgdir, sectors=len(run), flag_sectors=copies,
                     flag_offset=offsets.pop(), untouched_sha256=hu.hexdigest(), patched_sha256=ha.hexdigest(), store_sha256=hb.hexdigest(),
                     patched_rest_sha256=rest.hexdigest())
    finally:
        for f in files:
            f.close()
    if m:
        t, s = m["track"], m["store"]
        for what, got, want in (("the track's length", count * RAW, t["bytes"]), ("sector 0's place", s0, t["sector0"]),
                                ("the key", key, s["key"]), ("the store's version", version, s["version"]),
                                ("the directory's sector", pgdir, s["directory_sector"]), ("the store's sector count", len(run), s["sectors"]),
                                ("the flag sectors", copies, sorted(s["flag"]["sectors"])), ("the flag byte's offset", found["flag_offset"], s["flag"]["offset"]),
                                ("the untouched track's SHA-256", found["untouched_sha256"], t["untouched_sha256"]),
                                ("the patched track's SHA-256", found["patched_sha256"], t["patched_sha256"]),
                                ("the SHA-256 of the track with the store", found["store_sha256"], t["store_sha256"]),
                                ("the SHA-256 of the patched track without the store's sectors", found["patched_rest_sha256"], t["patched_rest_sha256"]),
                                ("the SHA-256 of the untouched track's data", data_sha, t.get("untouched_data_sha256"))):
            if got != want:
                raise bad(f"{what}: the tracks and A's own code give {got}, the manifest has {want}")
        if not (fr["sector"] <= loader and pgdir + len(run) <= fr["sector"] + fr["count"]):
            raise bad(f"the loader's sector {loader} and the store's sectors {pgdir}-{pgdir + len(run) - 1} are not inside the free run "
                      f"{fr['sector']}-{fr['sector'] + fr['count'] - 1}")
    return found


# ---------------------------------------------------------------- --verify
def verify(path, m, say=print):
    """which track is this; for one this release does not know: what its store, its flag, its own code and its sectors are, and
    whether it is this release's patched track outside the store (the exit statuses: the head of this file)"""
    pack17 = _mod("pack17")
    t, s, name = m["track"], m["store"], os.path.basename(str(path))
    h = file_sha256(path)
    known = {t["untouched_sha256"]: "the untouched track (not patched)", t["patched_sha256"]: "patched, without the store",
             t["store_sha256"]: "patched, with the store"}
    if h in known:
        say(f"{name}: {known[h]}")
        return OK
    say(f"{name}: not a track of this release (sha256 {h})")
    tr = open_track(path) if os.path.getsize(path) else None
    if tr is None:
        say("  not this game's data track (no boot record)")
        return INCONSISTENT
    try:
        n = tr.count - tr.base
        say(f"  layout: {tr.size:,}-byte sectors, sector 0 at file sector {tr.base}, {n:,} data sectors"
            + ("" if n == t["bytes"] // RAW - t["sector0"] else f" (the dump has {t['bytes'] // RAW - t['sector0']:,})"))
        ok = True
        flags = []
        for sector in s["flag"]["sectors"]:
            try:
                flags.append(tr.sectors(sector, 1)[s["flag"]["offset"]])
            except ValueError:
                flags.append(None)
        say("  store flag (sectors " + ", ".join(str(x) for x in s["flag"]["sectors"]) + f", byte {s['flag']['offset']}): "
            + ", ".join("past the end" if x is None else str(x) for x in flags))
        try:
            d = pack17.check(tr.sectors, s["directory_sector"])
        except ValueError:
            d = None
        places = list(s["flag"]["sectors"]) + [s["directory_sector"] - 1]      # the preload's copies and the loader's sector
        sigs, reads = [], True
        for sector in places:
            try:
                u = tr.sectors(sector, 1)
            except ValueError:
                u = b""
            sigs.append(code_signature(u))
            reads = reads and (sector == places[-1] or reads_directory(u, s["directory_sector"]))
        own = sigs[0] if None not in sigs and len(set(sigs)) == 1 else None
        say("  the track's own code (sectors " + ", ".join(str(x) for x in places) + "): "
            + (f"compares a store with version {own[0]}, key ${own[1]:04X}" if own else "no one store signature in it")
            + ("" if reads or not own else f", but does not read a directory from sector {s['directory_sector']}"))
        if d is None:
            say(f"  store: none (no directory at sector {s['directory_sector']})")
            if any(flags):
                ok = False
                say("  the flag is set but there is no store: NOT consistent")
        else:
            good = d["data_sha256_ok"] and d["count_ok"] and all(x["sha256_ok"] and x["sum_ok"] and x["padding_ok"] for x in d["segments"])
            say(f"  store directory at sector {s['directory_sector']}: version {d['version']}, key ${d['key']:04X}"
                f" ({'this release' if d['key'] == s['key'] and d['version'] == s['version'] else 'not this release'}'s), "
                f"{len(d['segments'])} segments, {d['data_sectors']} data sectors")
            say(f"    data SHA-256 {'ok' if d['data_sha256_ok'] else 'WRONG'}; segments' SHA-256 "
                f"{sum(x['sha256_ok'] for x in d['segments'])} of {len(d['segments'])} ok, sums {sum(x['sum_ok'] for x in d['segments'])} of "
                f"{len(d['segments'])} ok, padding {sum(x['padding_ok'] for x in d['segments'])} of {len(d['segments'])} ok")
            if not good:
                ok = False
                say("  the store does not agree with its own directory: NOT consistent")
            if not all(x == 1 for x in flags):
                ok = False
                say("  there is a store but the flag is not set in every copy: NOT consistent")
            why = console_refusal(tr.sectors, s["directory_sector"], own) if reads or not own else f"the track's own code does not read a directory from sector {s['directory_sector']}"
            say("  the console's own checks of the store (the directory against the track's own code, each segment's sum, the block): "
                + ("pass" if not why else f"the console would NOT load this store ({why}): NOT consistent"))
            if why:
                ok = False
        if tr.raw:
            edc = edc130().edc
            bad, checked, pregap, notdata = [], 0, 0, 0
            for k in range(tr.count):
                b = tr._at(k * RAW, RAW)
                if b[:12] != SYNC or b[15] != 1:            # (a dump's pregap may hold sectors that are not data: not counted against it)
                    pregap += k < tr.base
                    notdata += k >= tr.base
                    continue
                checked += 1
                if edc(b[:2064]) != b[2064:2068]:
                    bad.append(k - tr.base)
            say(f"  EDC: {checked:,} sectors checked, {len(bad)} wrong" + (f" (sectors {', '.join(str(x) for x in bad[:12])}{' ...' if len(bad) > 12 else ''})" if bad else "")
                + (f"; {notdata} sectors from sector 0 on are not data sectors" if notdata else "")
                + (f"; {pregap} sectors before sector 0 are not data sectors (the pregap: not checked)" if pregap else ""))
            if bad or notdata:
                ok = False
            if d is not None:
                ours = [s["directory_sector"] + i for i in range(1 + d["data_sectors"])] + list(s["flag"]["sectors"])
                same = 0
                for sector in ours:
                    b = tr._at((tr.base + sector) * RAW, RAW)
                    same += len(b) == RAW and _seal(bytearray(b)) == b
                say(f"  the store's and the flag's sectors equal a fresh EDC / ECC encode: {same} of {len(ours)}")
                ok = ok and same == len(ours)
        else:
            say("  EDC: not in this layout (2,048-byte sectors)")
        if tr.raw and tr.len == t["bytes"] and tr.base == t["sector0"]:
            rest = rest_sha256(path, m) == t["patched_rest_sha256"]
            say("  outside the store's sectors and the flag byte: " + ("this release's patched track" if rest else
                "NOT this release's patched track (another release's track, or one changed since it was patched)"))
        else:
            rest = False
            say("  outside the store's sectors and the flag byte: cannot be compared with this release's patched track in this layout")
        if not ok:
            say("  verdict: NOT consistent")
        elif not rest:
            say("  verdict: NOT a track of this release (what was checked of its store agrees; the rest of the track is not shown to be this release's)")
        else:
            say("  verdict: consistent with itself, but not a track this release makes (this release's patched track with something else in the store's sectors)")
        return SELF_CONSISTENT if ok and rest else INCONSISTENT
    finally:
        tr.close()


# ---------------------------------------------------------------- command line
def run_store(manifest, original, patched, say=print, err=None):
    """--store as a command: the messages and the exit status. Whatever happens ends in one sentence, never in a traceback."""
    err = err or (lambda line: print(line, file=sys.stderr))
    name = os.path.basename(str(patched))
    m = None
    try:
        m = load_manifest(manifest)
        got = add_store(original, patched, m)
    except StepError as e:
        err(f"{name} was not changed ({e}): it plays as it is, and {notice_of(m)}.")
        return FAILED
    except KeyboardInterrupt:
        err(f"{name} was not changed (interrupted): it plays as it is, and {notice_of(m)}.")
        return FAILED
    except Exception as e:                                  # add_store leaves PATCHED as it was on every error
        err(f"{name} was not changed (the step's own program stopped: {type(e).__name__}): it plays as it is, and {notice_of(m)}.")
        return FAILED
    say(f"{name}: the store is already in it; nothing to do" if got == "already" else f"{name}: the store was added")
    return OK


def run_verify(manifest, track, say=print, err=None):
    err = err or (lambda line: print(line, file=sys.stderr))
    name = os.path.basename(str(track))
    try:
        return verify(track, load_manifest(manifest), say)
    except StepError as e:
        err(f"{name} could not be checked ({e}).")
        return FAILED
    except KeyboardInterrupt:
        err(f"{name} could not be checked (interrupted).")
        return FAILED
    except OSError as e:
        err(f"{name} could not be checked (a file could not be read: {e.strerror or type(e).__name__}).")
        return FAILED
    except Exception as e:
        err(f"{name} could not be checked (the step's own program stopped: {type(e).__name__}).")
        return FAILED


def stop_on_signals():
    """a request to stop (STOP_SIGNALS: a kill, a closed terminal, Ctrl-\\, Ctrl-Break on Windows) is handled as Ctrl-C is: the
    temporary file goes. Skipped where there are no signals (a browser's Python) or outside the main thread."""
    try:
        import signal
    except ImportError:
        return

    def stop(*_a):
        raise KeyboardInterrupt
    for name in STOP_SIGNALS:
        try:
            signal.signal(getattr(signal, name), stop)
        except (AttributeError, OSError, ValueError, RuntimeError):
            pass


def main(argv):
    stop_on_signals()
    a = list(argv)
    if len(a) >= 2 and a[0] == "--manifest":
        man, a = a[1], a[2:]
        if len(a) == 3 and a[0] == "--store":
            return run_store(man, a[1], a[2])
        if len(a) == 2 and a[0] == "--verify":
            return run_verify(man, a[1])
    print(__doc__ or "storestep.py --manifest FILE (--store ORIGINAL PATCHED | --verify TRACK)", file=sys.stderr)
    return BAD_ARGS


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
