import '../models/pipeline_phase.dart';
import '../models/unlock_tool.dart';

extension UnlockToolPipeline on UnlockToolType {
  List<PipelinePhase> get pipeline => switch (this) {
        UnlockToolType.iCloudActivationLock => const [
            PipelinePhase(
              message: '[INIT] Opening lockdownd session via usbmuxd…',
              detail: 'USB channel 0x1A · pairing trust established',
            ),
            PipelinePhase(
              message: '[AUTH] Negotiating TLS 1.3 with activation subsystem…',
              detail: 'cipher: AES-256-GCM · cert chain validated',
            ),
            PipelinePhase(
              message: '[READ] Pulling MobileGestalt activation flags…',
              detail: 'ActivationState=Activated · FMI=Enabled',
            ),
            PipelinePhase(
              message: '[SYNC] Contacting albert.apple.com activation node…',
              detail: 'endpoint: init-p01st.push.apple.com:443',
            ),
            PipelinePhase(
              message: '[PARSE] Decoding activation_record.plist payload…',
              detail: 'FairPlay key bundle · 2,048-byte RSA block',
            ),
            PipelinePhase(
              message: '[KEY] Extracting SEP activation ticket reference…',
              detail: 'UID: 0x4F2A · enclave slot 0x03',
            ),
            PipelinePhase(
              message: '[UNBIND] Issuing Find My detach command to NVRAM…',
              detail: 'com.apple.fmip · token revocation pending',
            ),
            PipelinePhase(
              message: '[WRITE] Patching activation lock dword at 0x8C40…',
              detail: 'previous: 0x00000001 → target: 0x00000000',
            ),
            PipelinePhase(
              message: '[FLASH] Streaming signed unlock blob to baseband…',
              detail: 'chunk 14/14 · SHA-256 checksum OK',
            ),
            PipelinePhase(
              message: '[CLEAR] Purging iCloud account binding from lockdown store…',
              detail: 'AccountToken cache invalidated',
            ),
            PipelinePhase(
              message: '[RESET] Triggering soft reboot of activation daemon…',
              detail: 'lockdownd · awaiting device ACK',
            ),
            PipelinePhase(
              message: '[VERIFY] Re-reading activation state post-patch…',
              detail: 'FMI=Disabled · ActivationState=FactoryActivated',
            ),
            PipelinePhase(
              message: '[SIGN] Applying server-side unlock attestation…',
              detail: 'ticket ID: ULK-A7F2-9C01',
            ),
            PipelinePhase(
              message: '[COMMIT] Writing final unlock record to device EEPROM…',
              detail: 'atomic write · fsync confirmed',
            ),
            PipelinePhase(
              message: '[CHECK] Running post-unlock integrity scan…',
              detail: 'baseband · SEP · lockdownd — all PASS',
            ),
            PipelinePhase(
              message: '[DONE] iCloud activation lock removal complete.',
              detail: 'device ready for setup · safe to disconnect',
            ),
          ],
        UnlockToolType.carrierLock => const [
            PipelinePhase(
              message: '[INIT] Attaching to baseband diagnostic interface…',
              detail: 'QMI port open · chipset: Qualcomm X65',
            ),
            PipelinePhase(
              message: '[READ] Dumping carrier policy NV item 0x179…',
              detail: 'SIMLockStatus=1 · MCC-MNC: 234-15',
            ),
            PipelinePhase(
              message: '[DUMP] Extracting secro partition header…',
              detail: 'magic: SECR · version 0x00000007',
            ),
            PipelinePhase(
              message: '[DECRYPT] Unwrapping network unlock key with RSA-2048…',
              detail: 'carrier cert: Vodafone UK · expiry 2027',
            ),
            PipelinePhase(
              message: '[PARSE] Loading MCC/MNC restriction table…',
              detail: '42 carrier entries · 1 active lock',
            ),
            PipelinePhase(
              message: '[AUTH] Requesting unlock token from carrier gateway…',
              detail: 'HSS/HLR handshake · IMSI authenticated',
            ),
            PipelinePhase(
              message: '[GEN] Generating signed NCK unlock payload…',
              detail: '16-digit unlock code derived · checksum valid',
            ),
            PipelinePhase(
              message: '[WRITE] Programming NV item 550 with unlock flag…',
              detail: 'persistent_sim_lock → 0x00',
            ),
            PipelinePhase(
              message: '[PATCH] Updating modem firmware lock bitmask…',
              detail: 'bit[3:0] cleared · subsidy lock removed',
            ),
            PipelinePhase(
              message: '[FLASH] Pushing unlock certificate to secro block…',
              detail: '4096 bytes written · verify OK',
            ),
            PipelinePhase(
              message: '[RESET] Cycling baseband radio subsystem…',
              detail: 'RF front-end recalibrating…',
            ),
            PipelinePhase(
              message: '[PROBE] Probing SIM slot policy table…',
              detail: 'all MCC groups: UNLOCKED',
            ),
            PipelinePhase(
              message: '[SYNC] Refreshing carrier bundle profile…',
              detail: 'CommCenter · profile cache flushed',
            ),
            PipelinePhase(
              message: '[VERIFY] Confirming network registration eligibility…',
              detail: 'PS domain · LTE attach ready',
            ),
            PipelinePhase(
              message: '[SIGN] Sealing unlock with device hardware key…',
              detail: 'HMAC-SHA256 attestation applied',
            ),
            PipelinePhase(
              message: '[DONE] Carrier lock removal complete.',
              detail: 'device accepts all SIM profiles',
            ),
          ],
        UnlockToolType.imeiBlacklist => const [
            PipelinePhase(
              message: '[INIT] Establishing secure tunnel to GSMA IMEI DB…',
              detail: 'TLS 1.3 · gateway.imeidb.gsma.com',
            ),
            PipelinePhase(
              message: '[READ] Capturing device IMEI via diagnostic channel…',
              detail: 'TAC: 35XXXXXX · SVN: 08',
            ),
            PipelinePhase(
              message: '[QUERY] Scanning CEIR international blacklist…',
              detail: 'registries: 187 countries · 4 nodes',
            ),
            PipelinePhase(
              message: '[MATCH] Cross-referencing stolen/lost device reports…',
              detail: 'flag detected: REASON_CODE=LOST',
            ),
            PipelinePhase(
              message: '[AUTH] Submitting clearance request with device proof…',
              detail: 'ownership token · ECDSA P-256 signed',
            ),
            PipelinePhase(
              message: '[WAIT] Awaiting registry node acknowledgment…',
              detail: 'primary node: eu-west-1 · retry 1/3',
            ),
            PipelinePhase(
              message: '[PARSE] Decoding clearance response payload…',
              detail: 'status: PENDING_REVIEW → APPROVED',
            ),
            PipelinePhase(
              message: '[PROPAGATE] Pushing status update to regional CEIR mirrors…',
              detail: '12/12 nodes synced',
            ),
            PipelinePhase(
              message: '[CLEAR] Removing IMEI from lost/stolen index…',
              detail: 'entry hash: 0x9F3C21A8 deleted',
            ),
            PipelinePhase(
              message: '[UPDATE] Writing CLEAN status to master registry…',
              detail: 'IMEI status: BLACKLISTED → WHITELISTED',
            ),
            PipelinePhase(
              message: '[SYNC] Flushing carrier-side IMEI cache…',
              detail: 'HSS/EIR record updated',
            ),
            PipelinePhase(
              message: '[VERIFY] Running secondary blacklist scan…',
              detail: '0 flags remaining · scan PASS',
            ),
            PipelinePhase(
              message: '[LOG] Recording clearance transaction ID…',
              detail: 'TXN-IMEI-2026-7F4A2B91',
            ),
            PipelinePhase(
              message: '[NOTIFY] Broadcasting unlock to partner networks…',
              detail: 'GSMA partner API · HTTP 200',
            ),
            PipelinePhase(
              message: '[CHECK] Confirming device radio eligibility…',
              detail: 'network attach: permitted',
            ),
            PipelinePhase(
              message: '[DONE] IMEI blacklist clearance complete.',
              detail: 'device cleared on all registries',
            ),
          ],
        UnlockToolType.frpRemoval => const [
            PipelinePhase(
              message: '[INIT] Enumerating Android security partitions…',
              detail: 'found: frp,persist,modemst1,modemst2',
            ),
            PipelinePhase(
              message: '[ADB] Elevating shell to engmode diagnostic…',
              detail: 'uid: 2000 · SELinux permissive',
            ),
            PipelinePhase(
              message: '[READ] Mounting /dev/block/by-name/frp (read-only)…',
              detail: 'ext4 · 512 KB · inode 0x0021',
            ),
            PipelinePhase(
              message: '[DUMP] Extracting FRP credential block…',
              detail: 'Google account hash: 0xA4…F2 (64 bytes)',
            ),
            PipelinePhase(
              message: '[PARSE] Decoding persistent_data_block header…',
              detail: 'magic: 0x50444230 · version 1',
            ),
            PipelinePhase(
              message: '[KEY] Deriving unlock key from hardware attestation…',
              detail: 'TEE · StrongBox · RSA-2048',
            ),
            PipelinePhase(
              message: '[UNBIND] Removing Google account FRP binding…',
              detail: 'account_id reference cleared',
            ),
            PipelinePhase(
              message: '[WRITE] Zeroing FRP partition credential sector…',
              detail: 'offset 0x1000 · 4 KB wiped',
            ),
            PipelinePhase(
              message: '[PATCH] Updating ro.frp.pst flag in property store…',
              detail: '/dev/block/persistent · flag=0',
            ),
            PipelinePhase(
              message: '[CLEAR] Flushing Gatekeeper / credential encrypted storage…',
              detail: 'SPAE · synthetic password reset',
            ),
            PipelinePhase(
              message: '[RESET] Invalidating factory reset protection token…',
              detail: 'PDB version incremented',
            ),
            PipelinePhase(
              message: '[FLASH] Writing blank FRP header with valid checksum…',
              detail: 'CRC32: 0x8B4E21C0',
            ),
            PipelinePhase(
              message: '[REBOOT] Signaling zygote to reload security policy…',
              detail: 'system_server notified',
            ),
            PipelinePhase(
              message: '[VERIFY] Re-reading FRP partition post-write…',
              detail: 'account binding: NONE · PASS',
            ),
            PipelinePhase(
              message: '[BOOT] Verifying factory reset boot path…',
              detail: 'setup wizard: UNLOCKED',
            ),
            PipelinePhase(
              message: '[DONE] FRP removal complete.',
              detail: 'device boots without Google account lock',
            ),
          ],
      };
}
