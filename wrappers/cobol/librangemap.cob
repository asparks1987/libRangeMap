       IDENTIFICATION DIVISION.
       PROGRAM-ID. LIBRANGEMAP.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-INPUT-MIN     PIC S9(09) COMP.
       01  WS-INPUT-MAX     PIC S9(09) COMP.
       01  WS-VALUE         PIC S9(09) COMP.
       01  WS-OUTPUT-MIN    PIC S9(03)V9(09) COMP-2.
       01  WS-OUTPUT-MAX    PIC S9(03)V9(09) COMP-2.
       01  WS-OUTPUT-FALSE  PIC S9(03)V9(09) COMP-2.
       01  WS-OUTPUT-TRUE   PIC S9(03)V9(09) COMP-2.
       01  WS-CLIP          PIC X VALUE 'N'.
       01  WS-INPUT-SPAN    PIC S9(09) COMP.
       01  WS-OUTPUT-SPAN   PIC S9(03)V9(09) COMP-2.
       01  WS-SEQ-ALLOW-EMPTY PIC X VALUE 'N'.
       01  WS-MAP-STATUS    PIC X(20) VALUE SPACES.
       01  WS-MAP-ERROR     PIC X(60) VALUE SPACES.
       01  WS-OBJ-INDEX     PIC S9(04) COMP VALUE 0.
       01  WS-IMG-INDEX     PIC S9(09) COMP VALUE 0.
       01  WS-IMG-OUT-LIMIT PIC S9(09) COMP VALUE 4096.
       01  WS-TEMP-BYTE     PIC X     VALUE SPACE.
       01  WS-BYTE-VALUE    PIC S9(03) COMP VALUE 0.
       01  WS-TYPE-CODE     PIC X      VALUE SPACE.
       01  WS-FLOAT-SPAN    PIC S9(03)V9(09) COMP-2 VALUE 0.
       01  WS-TYPED-OUT-MIN PIC S9(03)V9(09) COMP-2.
       01  WS-TYPED-OUT-MAX PIC S9(03)V9(09) COMP-2.
       01  WS-TEXT-LEN      PIC S9(04) COMP VALUE 0.
       01  WS-TEXT-ALLOW-EMPTY PIC X VALUE 'N'.
       01  WS-TEXT-CLIP    PIC X VALUE 'N'.
       01  WS-TEXT-IN      PIC X(256).
       01  WS-TEXT-OUT-COUNT PIC S9(04) COMP VALUE 0.
       01  WS-TEXT-OUT-VALUES PIC S9(03)V9(09) COMP-2 OCCURS 256.
       01  WS-TEXT-INDEX   PIC S9(04) COMP VALUE 0.
       01  WS-TEMPORAL-UNIT PIC X VALUE 'S'.
       01  WS-TEMPORAL-NUM  PIC S9(12)V9(09) COMP-2 VALUE 0.
       01  WS-TEMPORAL-OUT  PIC S9(03)V9(09) COMP-2 VALUE 0.
       01  WS-CAT-IN-LEN      PIC S9(03) COMP VALUE 0.
       01  WS-CAT-ALLOW-EMPTY PIC X VALUE 'N'.
       01  WS-CAT-INPUT       PIC X(16).
       01  WS-CAT-VOCAB-SIZE  PIC S9(03) COMP VALUE 0.
       01  WS-CAT-VOCAB       PIC X(16) OCCURS 32.
       01  WS-CAT-INDEX       PIC S9(04) COMP VALUE 0.
       01  WS-CAT-J-INDEX     PIC S9(04) COMP VALUE 0.
       01  WS-CAT-MATCH       PIC X VALUE 'N'.
       01  WS-CAT-MATCH-INDEX PIC S9(04) COMP VALUE 0.
       01  WS-CAT-NUM         PIC S9(12)V9(09) COMP-2 VALUE 0.
       01  WS-CAT-OUT         PIC S9(03)V9(09) COMP-2 VALUE 0.
       01  WS-BYTES-IN-LEN PIC S9(09) COMP VALUE 0.
       01  WS-BYTES-ALLOW-EMPTY PIC X VALUE 'N'.
       01  WS-BYTES-CLIP    PIC X VALUE 'N'.
       01  WS-BYTES-IN      PIC X(4096).
       01  WS-BYTES-OUT-COUNT PIC S9(09) COMP VALUE 0.
       01  WS-BYTES-OUT-VALUES PIC S9(03)V9(09) COMP-2 OCCURS 4096.
       01  WS-BYTES-INDEX   PIC S9(09) COMP VALUE 0.
       01  WS-CALC-ROWS     PIC S9(09) COMP VALUE 0.
       01  WS-CALC-COLS     PIC S9(09) COMP VALUE 0.
       01  WS-CALC-CHANNELS PIC S9(09) COMP VALUE 0.
       01  WS-CALC-COUNT    PIC S9(09) COMP VALUE 0.
       01  WS-BOOL-VALUE    PIC X VALUE SPACE.

       01  WS-OBJ-FIELD-COUNT     PIC S9(04) COMP VALUE 0.
       01  WS-OBJ-ALLOW-UNKNOWN   PIC X VALUE 'N'.
       01  WS-OBJ-ALLOW-EMPTY     PIC X VALUE 'N'.
       01  WS-OBJ-CLIP            PIC X VALUE 'N'.
       01  WS-OBJ-KEYS.
           05  WS-OBJ-KEY         PIC X(16) OCCURS 16.
       01  WS-OBJ-TYPE-CODES.
           05  WS-OBJ-TYPE-CODE   PIC X      OCCURS 16.
       01  WS-OBJ-INPUT-INT.
           05  WS-OBJ-IN-INT      PIC S9(09) COMP     OCCURS 16.
       01  WS-OBJ-INPUT-FLOAT.
           05  WS-OBJ-IN-FLOAT    PIC S9(03)V9(09) COMP-2 OCCURS 16.
       01  WS-OBJ-INPUT-FLOAT-MIN.
           05  WS-OBJ-IN-FLOAT-MIN PIC S9(03)V9(09) COMP-2 OCCURS 16.
       01  WS-OBJ-INPUT-FLOAT-MAX.
           05  WS-OBJ-IN-FLOAT-MAX PIC S9(03)V9(09) COMP-2 OCCURS 16.
       01  WS-OBJ-INPUT-BOOL.
           05  WS-OBJ-IN-BOOL     PIC X           OCCURS 16.
       01  WS-OBJ-INPUT-BYTES-IN.
           05  WS-OBJ-IN-BYTES    PIC X(255) OCCURS 16.
       01  WS-OBJ-OUTPUT-VALUES.
           05  WS-OBJ-OUT-VALUE   PIC S9(03)V9(09) COMP-2 OCCURS 16.

       01  WS-IMG-BYTES-IN         PIC X(65535).
       01  WS-IMG-BYTES-COUNT      PIC S9(09) COMP VALUE 0.
       01  WS-IMG-ROWS             PIC S9(09) COMP VALUE 0.
       01  WS-IMG-COLS             PIC S9(09) COMP VALUE 0.
       01  WS-IMG-CHANNELS         PIC S9(09) COMP VALUE 0.
       01  WS-IMG-MODE             PIC X(4) VALUE "AUTO".
       01  WS-IMG-ALLOW-EMPTY      PIC X VALUE 'N'.
       01  WS-IMG-CLIP             PIC X VALUE 'N'.
       01  WS-IMG-OUT-COUNT        PIC S9(09) COMP VALUE 0.
       01  WS-IMG-OUT-VALUES       PIC S9(03)V9(09) COMP-2 OCCURS 4096.

       PROCEDURE DIVISION USING
             WS-VALUE WS-INPUT-MIN WS-INPUT-MAX WS-OUTPUT-MIN WS-OUTPUT-MAX WS-CLIP
             RETURNING WS-OUTPUT-SPAN.

       * Placeholder algorithm reference.
       * Map = outputMin + ((value - inputMin) / (inputMax - inputMin)) * (outputMax - outputMin)
       * Float and boolean entrypoints follow the same explicit validation pattern.
       * Map_Float = outputMin + ((value - inputMin) / (inputMax - inputMin)) * (outputMax - outputMin)
       * Map_Boolean returns outputFalse or outputTrue after validating the logical input contract.
       * Map_Sequence applies the integer formula element-by-element, preserves shape for nested lists,
       * rejects empty sequences unless an explicit allow-empty flag is set, and fails on unknown element types.
       * Planned categorical extension: explicit vocabulary lookup with duplicate/unknown token rejection.
       *
       * Map/Object implemented schema extension:
       *   - schema-driven record families only (static field list per runtime schema)
       *   - unknown fields rejected unless explicitly allowed
       *   - missing required fields rejected unless allow-empty behavior is explicitly configured
       *   - boolean/numeric fields mapped explicitly via schema descriptors
       *   - no implicit coercion of unsupported types; each family must be explicitly represented.
       *   - status/error contract:
       *       WS-MAP-STATUS = OK / ERR-UNKNOWN-FIELD / ERR-MISSING-FIELD / ERR-SCHEMA.
       *   - schema input: fixed-field descriptor arrays in WS-OBJ-* areas (field_count, key, field_type, min/max values).
       * Temporal extension:
       *   - POSIX seconds/milliseconds input domain with explicit unit policy (S/M)
       *   - clipping policy follows WS-CLIP
       *   - strict finite-range checks, explicit out-of-range and schema failures
       * Categorical extension:
       *   - explicit vocabulary lookup with duplicate/unknown token rejection
       *   - empty input policy and explicit status/error contract:
       *       WS-MAP-STATUS = OK / ERR-EMPTY / ERR-SCHEMA / ERR-UNKNOWN-TOKEN.
       *   - strict output-range checks via shared clipping policy and canonical formula.
       * Image-like implemented extension:
       *   - fixed-shape or raw-flattened byte/image array mapping
       *   - explicit row/column/channel configuration or explicit flattened mode required
       *   - empty images rejected unless explicit allow-empty policy is set
       *   - non-byte inputs rejected
       *   - status/error contract:
       *       WS-MAP-STATUS = OK / ERR-NON-BYTE / ERR-IMAGE-SHAPE / ERR-EMPTY / ERR-SCHEMA
       MAP-TEXT-VALUE-SECTION.
           MOVE SPACES TO WS-MAP-STATUS WS-MAP-ERROR.
           MOVE 0 TO WS-TEXT-OUT-COUNT.

           IF WS-TEXT-LEN < 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "TEXT-LENGTH-MUST-NOT-BE-NEGATIVE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-TEXT-LEN = 0
              IF WS-TEXT-ALLOW-EMPTY = 'Y'
                 MOVE "OK" TO WS-MAP-STATUS
                 GOBACK
              END-IF
              MOVE "ERR-EMPTY" TO WS-MAP-STATUS
              MOVE "TEXT-LEN-MUST-BE-POSITIVE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-TEXT-LEN > 256
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "TEXT-LENGTH-EXCEEDS-FIXED-LIMIT-256" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-TEXT-ALLOW-EMPTY NOT = 'Y'
           AND WS-TEXT-ALLOW-EMPTY NOT = 'N'
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "TEXT-ALLOW-EMPTY-MUST-BE-Y-OR-N" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-TEXT-CLIP NOT = 'Y'
           AND WS-TEXT-CLIP NOT = 'N'
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "TEXT-CLIP-MUST-BE-Y-OR-N" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-INPUT-MIN >= WS-INPUT-MAX
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "TEXT-MAPPER-REQUIRES-NON-EMPTY-FLOAT-RANGE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           COMPUTE WS-INPUT-SPAN = WS-INPUT-MAX - WS-INPUT-MIN.
           COMPUTE WS-OUTPUT-SPAN = WS-OUTPUT-MAX - WS-OUTPUT-MIN.

           IF WS-OUTPUT-SPAN = 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "TEXT-OUTPUT-RANGE-SPAN-MUST-BE-NON-ZERO" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           MOVE 1 TO WS-TEXT-INDEX
           PERFORM VARYING WS-TEXT-INDEX FROM 1 BY 1
                   UNTIL WS-TEXT-INDEX > WS-TEXT-LEN
               MOVE WS-TEXT-IN(WS-TEXT-INDEX:1) TO WS-TEMP-BYTE
               COMPUTE WS-BYTE-VALUE = FUNCTION ORD(WS-TEMP-BYTE)

               IF WS-BYTE-VALUE < 0 OR WS-BYTE-VALUE > 255
                  MOVE "ERR-NON-BYTE" TO WS-MAP-STATUS
                  MOVE "TEXT-VALUE-MUST-BE-BYTE-CHARACTERS" TO WS-MAP-ERROR
                  GOBACK
               END-IF

               IF WS-BYTE-VALUE < WS-INPUT-MIN
                  IF WS-TEXT-CLIP = 'Y'
                     MOVE WS-INPUT-MIN TO WS-BYTE-VALUE
                  ELSE
                     MOVE "ERR-OUT-OF-RANGE" TO WS-MAP-STATUS
                     MOVE "TEXT-CODEPOINT-OUT-OF-RANGE" TO WS-MAP-ERROR
                     GOBACK
                  END-IF
               END-IF

               IF WS-BYTE-VALUE > WS-INPUT-MAX
                  IF WS-TEXT-CLIP = 'Y'
                     MOVE WS-INPUT-MAX TO WS-BYTE-VALUE
                  ELSE
                     MOVE "ERR-OUT-OF-RANGE" TO WS-MAP-STATUS
                     MOVE "TEXT-CODEPOINT-OUT-OF-RANGE" TO WS-MAP-ERROR
                     GOBACK
                  END-IF
               END-IF

               COMPUTE WS-TEXT-OUT-VALUES(WS-TEXT-INDEX) =
                 WS-OUTPUT-MIN +
                 ((WS-BYTE-VALUE - WS-INPUT-MIN) / WS-INPUT-SPAN) *
                 WS-OUTPUT-SPAN

               ADD 1 TO WS-TEXT-OUT-COUNT
           END-PERFORM.

           MOVE "OK" TO WS-MAP-STATUS.
           MOVE SPACES TO WS-MAP-ERROR.
           GOBACK.

       MAP-BYTES-VALUE-SECTION.
           MOVE SPACES TO WS-MAP-STATUS WS-MAP-ERROR.
           MOVE 0 TO WS-BYTES-OUT-COUNT.

           IF WS-BYTES-IN-LEN < 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "BYTES-LENGTH-MUST-NOT-BE-NEGATIVE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-BYTES-IN-LEN = 0
              IF WS-BYTES-ALLOW-EMPTY = 'Y'
                 MOVE "OK" TO WS-MAP-STATUS
                 GOBACK
              END-IF
              MOVE "ERR-EMPTY" TO WS-MAP-STATUS
              MOVE "BYTES-LEN-MUST-BE-POSITIVE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-BYTES-IN-LEN > WS-IMG-OUT-LIMIT
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "BYTES-LEN-EXCEEDS-FIXED-LIMIT" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-BYTES-ALLOW-EMPTY NOT = 'Y'
           AND WS-BYTES-ALLOW-EMPTY NOT = 'N'
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "BYTES-ALLOW-EMPTY-MUST-BE-Y-OR-N" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-BYTES-CLIP NOT = 'Y'
           AND WS-BYTES-CLIP NOT = 'N'
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "BYTES-CLIP-MUST-BE-Y-OR-N" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-INPUT-MIN >= WS-INPUT-MAX
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "BYTES-MAPPER-REQUIRES-NON-EMPTY-FLOAT-RANGE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           COMPUTE WS-INPUT-SPAN = WS-INPUT-MAX - WS-INPUT-MIN.
           COMPUTE WS-OUTPUT-SPAN = WS-OUTPUT-MAX - WS-OUTPUT-MIN.

           IF WS-OUTPUT-SPAN = 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "BYTES-OUTPUT-RANGE-SPAN-MUST-BE-NON-ZERO" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           MOVE 1 TO WS-BYTES-INDEX
           PERFORM VARYING WS-BYTES-INDEX FROM 1 BY 1
                   UNTIL WS-BYTES-INDEX > WS-BYTES-IN-LEN
               MOVE WS-BYTES-IN(WS-BYTES-INDEX:1) TO WS-TEMP-BYTE
               COMPUTE WS-BYTE-VALUE = FUNCTION ORD(WS-TEMP-BYTE)

               IF WS-BYTE-VALUE < 0 OR WS-BYTE-VALUE > 255
                  MOVE "ERR-NON-BYTE" TO WS-MAP-STATUS
                  MOVE "BYTES-MUST-CONTAIN-RAW-BYTES-ONLY" TO WS-MAP-ERROR
                  GOBACK
               END-IF

               IF WS-BYTE-VALUE < WS-INPUT-MIN
                  IF WS-BYTES-CLIP = 'Y'
                     MOVE WS-INPUT-MIN TO WS-BYTE-VALUE
                  ELSE
                     MOVE "ERR-OUT-OF-RANGE" TO WS-MAP-STATUS
                     MOVE "BYTES-VALUE-OUT-OF-RANGE" TO WS-MAP-ERROR
                     GOBACK
                  END-IF
               END-IF

               IF WS-BYTE-VALUE > WS-INPUT-MAX
                  IF WS-BYTES-CLIP = 'Y'
                     MOVE WS-INPUT-MAX TO WS-BYTE-VALUE
                  ELSE
                     MOVE "ERR-OUT-OF-RANGE" TO WS-MAP-STATUS
                     MOVE "BYTES-VALUE-OUT-OF-RANGE" TO WS-MAP-ERROR
                     GOBACK
                  END-IF
               END-IF

               COMPUTE WS-BYTES-OUT-VALUES(WS-BYTES-INDEX) =
                 WS-OUTPUT-MIN +
                 ((WS-BYTE-VALUE - WS-INPUT-MIN) / WS-INPUT-SPAN) *
                 WS-OUTPUT-SPAN

               ADD 1 TO WS-BYTES-OUT-COUNT
           END-PERFORM.

           MOVE "OK" TO WS-MAP-STATUS.
           MOVE SPACES TO WS-MAP-ERROR.
           GOBACK.

       MAP-TEMPORAL-VALUE-SECTION.
           MOVE SPACES TO WS-MAP-STATUS WS-MAP-ERROR.
           MOVE 0 TO WS-TEMPORAL-OUT.

           IF WS-TEMPORAL-UNIT NOT = "S"
           AND WS-TEMPORAL-UNIT NOT = "M"
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "TEMPORAL-UNIT-MUST-BE-S-SECONDS-OR-M-MILLISECONDS" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-CLIP NOT = 'Y'
           AND WS-CLIP NOT = 'N'
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "TEMPORAL-CLIP-MUST-BE-Y-OR-N" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-INPUT-MIN >= WS-INPUT-MAX
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "TEMPORAL-MAPPER-REQUIRES-NON-EMPTY-FLOAT-RANGE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           COMPUTE WS-INPUT-SPAN = WS-INPUT-MAX - WS-INPUT-MIN.
           COMPUTE WS-OUTPUT-SPAN = WS-OUTPUT-MAX - WS-OUTPUT-MIN.

           IF WS-OUTPUT-SPAN = 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "TEMPORAL-OUTPUT-RANGE-SPAN-MUST-BE-NON-ZERO" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           MOVE WS-VALUE TO WS-TEMPORAL-NUM.
           IF WS-TEMPORAL-UNIT = "M"
              COMPUTE WS-TEMPORAL-NUM = WS-VALUE / 1000.0
           END-IF.

           IF WS-TEMPORAL-NUM < WS-INPUT-MIN
              IF WS-CLIP = 'Y'
                 MOVE WS-INPUT-MIN TO WS-TEMPORAL-NUM
              ELSE
                 MOVE "ERR-OUT-OF-RANGE" TO WS-MAP-STATUS
                 MOVE "TEMPORAL-VALUE-OUT-OF-RANGE" TO WS-MAP-ERROR
                 GOBACK
              END-IF
           END-IF.

           IF WS-TEMPORAL-NUM > WS-INPUT-MAX
              IF WS-CLIP = 'Y'
                 MOVE WS-INPUT-MAX TO WS-TEMPORAL-NUM
              ELSE
                 MOVE "ERR-OUT-OF-RANGE" TO WS-MAP-STATUS
                 MOVE "TEMPORAL-VALUE-OUT-OF-RANGE" TO WS-MAP-ERROR
                 GOBACK
              END-IF
           END-IF.

           COMPUTE WS-TEMPORAL-OUT =
             WS-OUTPUT-MIN +
             ((WS-TEMPORAL-NUM - WS-INPUT-MIN) / WS-INPUT-SPAN) * WS-OUTPUT-SPAN

           MOVE "OK" TO WS-MAP-STATUS.
           MOVE SPACES TO WS-MAP-ERROR.
           GOBACK.

       MAP-CATEGORICAL-VALUE-SECTION.
           MOVE SPACES TO WS-MAP-STATUS WS-MAP-ERROR.
           MOVE 0 TO WS-CAT-OUT.

           IF WS-CAT-IN-LEN < 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "CATEGORICAL-IN-LEN-MUST-NOT-BE-NEGATIVE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-CAT-IN-LEN = 0
              IF WS-CAT-ALLOW-EMPTY = 'Y'
                 MOVE WS-OUTPUT-MIN TO WS-CAT-OUT
                 MOVE "OK" TO WS-MAP-STATUS
                 MOVE SPACES TO WS-MAP-ERROR
                 GOBACK
              END-IF
              MOVE "ERR-EMPTY" TO WS-MAP-STATUS
              MOVE "CATEGORICAL-TOKEN-MUST-NOT-BE-EMPTY" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-CAT-IN-LEN > 16
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "CATEGORICAL-IN-LEN-EXCEEDS-16" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-CAT-ALLOW-EMPTY NOT = 'Y'
           AND WS-CAT-ALLOW-EMPTY NOT = 'N'
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "CATEGORICAL-ALLOW-EMPTY-MUST-BE-Y-OR-N" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-CLIP NOT = 'Y'
           AND WS-CLIP NOT = 'N'
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "CATEGORICAL-CLIP-MUST-BE-Y-OR-N" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-CAT-VOCAB-SIZE < 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "CATEGORICAL-VOCAB-SIZE-MUST-NOT-BE-NEGATIVE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-CAT-VOCAB-SIZE = 0
              IF WS-CAT-ALLOW-EMPTY = 'Y'
                 MOVE WS-OUTPUT-MIN TO WS-CAT-OUT
                 MOVE "OK" TO WS-MAP-STATUS
                 MOVE SPACES TO WS-MAP-ERROR
                 GOBACK
              END-IF
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "CATEGORICAL-VOCAB-MUST-NOT-BE-EMPTY" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-CAT-VOCAB-SIZE > 32
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "CATEGORICAL-VOCAB-SIZE-EXCEEDS-LIMIT-32" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-INPUT-MIN >= WS-INPUT-MAX
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "CATEGORICAL-MAPPER-REQUIRES-NON-EMPTY-FLOAT-RANGE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           COMPUTE WS-INPUT-SPAN = WS-INPUT-MAX - WS-INPUT-MIN.
           COMPUTE WS-OUTPUT-SPAN = WS-OUTPUT-MAX - WS-OUTPUT-MIN.
           IF WS-OUTPUT-SPAN = 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "CATEGORICAL-OUTPUT-RANGE-SPAN-MUST-BE-NON-ZERO" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           MOVE 1 TO WS-CAT-INDEX
           MOVE 0 TO WS-CAT-MATCH-INDEX
           MOVE 'N' TO WS-CAT-MATCH.

           PERFORM VARYING WS-CAT-INDEX FROM 1 BY 1
                   UNTIL WS-CAT-INDEX > WS-CAT-VOCAB-SIZE
               IF WS-CAT-VOCAB(WS-CAT-INDEX) = SPACES
                  MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
                  MOVE "CATEGORICAL-VOCAB-TOKEN-MUST-NOT-BE-EMPTY" TO WS-MAP-ERROR
                  GOBACK
               END-IF

               MOVE WS-CAT-INDEX TO WS-CAT-J-INDEX
               ADD 1 TO WS-CAT-J-INDEX
               PERFORM VARYING WS-CAT-J-INDEX FROM WS-CAT-J-INDEX BY 1
                       UNTIL WS-CAT-J-INDEX > WS-CAT-VOCAB-SIZE
                   IF WS-CAT-VOCAB(WS-CAT-INDEX) = WS-CAT-VOCAB(WS-CAT-J-INDEX)
                      MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
                      MOVE "CATEGORICAL-VOCAB-MUST-BE-UNIQUE" TO WS-MAP-ERROR
                      GOBACK
                   END-IF
               END-PERFORM

               IF WS-CAT-VOCAB(WS-CAT-INDEX) = WS-CAT-INPUT
                  MOVE 'Y' TO WS-CAT-MATCH
                  MOVE WS-CAT-INDEX TO WS-CAT-MATCH-INDEX
                  EXIT PERFORM
               END-IF
           END-PERFORM.

           IF WS-CAT-MATCH NOT = 'Y'
              MOVE "ERR-UNKNOWN-TOKEN" TO WS-MAP-STATUS
              MOVE "CATEGORICAL-TOKEN-NOT-IN-VOCAB" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           COMPUTE WS-CAT-NUM = WS-CAT-MATCH-INDEX - 1.

           IF WS-CAT-NUM < WS-INPUT-MIN
              IF WS-CLIP = 'Y'
                 MOVE WS-INPUT-MIN TO WS-CAT-NUM
              ELSE
                 MOVE "ERR-OUT-OF-RANGE" TO WS-MAP-STATUS
                 MOVE "CATEGORICAL-VALUE-OUT-OF-RANGE" TO WS-MAP-ERROR
                 GOBACK
              END-IF
           END-IF.

           IF WS-CAT-NUM > WS-INPUT-MAX
              IF WS-CLIP = 'Y'
                 MOVE WS-INPUT-MAX TO WS-CAT-NUM
              ELSE
                 MOVE "ERR-OUT-OF-RANGE" TO WS-MAP-STATUS
                 MOVE "CATEGORICAL-VALUE-OUT-OF-RANGE" TO WS-MAP-ERROR
                 GOBACK
              END-IF
           END-IF.

           COMPUTE WS-CAT-OUT =
             WS-OUTPUT-MIN +
             ((WS-CAT-NUM - WS-INPUT-MIN) / WS-INPUT-SPAN) * WS-OUTPUT-SPAN

           MOVE "OK" TO WS-MAP-STATUS.
           MOVE SPACES TO WS-MAP-ERROR.
           GOBACK.

       MAP-OBJECT-VALUE-SECTION.
           MOVE SPACES TO WS-MAP-STATUS WS-MAP-ERROR.
           MOVE 0 TO WS-OBJ-INDEX.

           IF WS-OBJ-FIELD-COUNT < 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "OBJECT-FIELD-COUNT-MUST-NOT-BE-NEGATIVE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-OBJ-FIELD-COUNT = 0
              IF WS-OBJ-ALLOW-EMPTY = 'Y'
                 MOVE "OK" TO WS-MAP-STATUS
                 GOBACK
              END-IF
              MOVE "ERR-EMPTY" TO WS-MAP-STATUS
              MOVE "OBJECT-FIELD-COUNT-MUST-BE-POSITIVE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-OBJ-FIELD-COUNT > 16
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "OBJECT-FIELD-COUNT-EXCEEDS-FIXED-SCHEMA-LIMIT-16" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-INPUT-MIN >= WS-INPUT-MAX
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "OBJECT-MAPPER-REQUIRES-NON-EMPTY-FLOAT-RANGE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           COMPUTE WS-INPUT-SPAN = WS-INPUT-MAX - WS-INPUT-MIN.
           IF WS-OBJ-ALLOW-UNKNOWN NOT = 'Y'
           AND WS-OBJ-ALLOW-UNKNOWN NOT = 'N'
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "OBJECT-ALLOW-UNKNOWN-MUST-BE-Y-OR-N" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-OBJ-ALLOW-EMPTY NOT = 'Y'
           AND WS-OBJ-ALLOW-EMPTY NOT = 'N'
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "OBJECT-ALLOW-EMPTY-MUST-BE-Y-OR-N" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-OBJ-CLIP NOT = 'Y'
           AND WS-OBJ-CLIP NOT = 'N'
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "OBJECT-CLIP-MUST-BE-Y-OR-N" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           COMPUTE WS-OUTPUT-SPAN = WS-OUTPUT-MAX - WS-OUTPUT-MIN.
           IF WS-OUTPUT-SPAN = 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "OBJECT-OUTPUT-RANGE-SPAN-MUST-BE-NON-ZERO" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           MOVE 1 TO WS-OBJ-INDEX
           PERFORM VARYING WS-OBJ-INDEX FROM 1 BY 1
                   UNTIL WS-OBJ-INDEX > WS-OBJ-FIELD-COUNT
               IF WS-OBJ-KEYS(WS-OBJ-INDEX) = SPACES
                  IF WS-OBJ-ALLOW-EMPTY NOT = 'Y'
                     MOVE "ERR-MISSING-FIELD" TO WS-MAP-STATUS
                     MOVE "OBJECT-FIELD-KEYS-MUST-BE-SUPPLIED" TO WS-MAP-ERROR
                     GOBACK
                  END-IF
                  MOVE 0 TO WS-OBJ-OUT-VALUE(WS-OBJ-INDEX)
                  CONTINUE
               END-IF

               MOVE WS-OBJ-TYPE-CODES(WS-OBJ-INDEX) TO WS-TYPE-CODE
               IF WS-TYPE-CODE = 'I'
                  IF WS-OBJ-IN-INT(WS-OBJ-INDEX) < WS-INPUT-MIN
                     IF WS-OBJ-CLIP = 'Y'
                        MOVE WS-INPUT-MIN TO WS-OBJ-IN-INT(WS-OBJ-INDEX)
                     ELSE
                        MOVE "ERR-OUT-OF-RANGE" TO WS-MAP-STATUS
                        MOVE "OBJECT-INT-FIELD-OUT-OF-RANGE" TO WS-MAP-ERROR
                        GOBACK
                     END-IF
                  END-IF

                  IF WS-OBJ-IN-INT(WS-OBJ-INDEX) > WS-INPUT-MAX
                     IF WS-OBJ-CLIP = 'Y'
                        MOVE WS-INPUT-MAX TO WS-OBJ-IN-INT(WS-OBJ-INDEX)
                     ELSE
                        MOVE "ERR-OUT-OF-RANGE" TO WS-MAP-STATUS
                        MOVE "OBJECT-INT-FIELD-OUT-OF-RANGE" TO WS-MAP-ERROR
                        GOBACK
                     END-IF
                  END-IF

                  COMPUTE WS-OBJ-OUT-VALUE(WS-OBJ-INDEX) =
                    WS-OUTPUT-MIN +
                    ((WS-OBJ-IN-INT(WS-OBJ-INDEX) - WS-INPUT-MIN) / WS-INPUT-SPAN) *
                    WS-OUTPUT-SPAN
               ELSE IF WS-TYPE-CODE = 'F'
                  COMPUTE WS-FLOAT-SPAN =
                    WS-OBJ-IN-FLOAT-MAX(WS-OBJ-INDEX) - WS-OBJ-IN-FLOAT-MIN(WS-OBJ-INDEX)
                  IF WS-FLOAT-SPAN <= 0
                     MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
                     MOVE "OBJECT-FLOAT-RANGE-SPAN-MUST-BE-POSITIVE" TO WS-MAP-ERROR
                     GOBACK
                  END-IF

                  IF WS-OBJ-IN-FLOAT(WS-OBJ-INDEX) < WS-OBJ-IN-FLOAT-MIN(WS-OBJ-INDEX)
                     IF WS-OBJ-CLIP = 'Y'
                        MOVE WS-OBJ-IN-FLOAT-MIN(WS-OBJ-INDEX) TO WS-OBJ-IN-FLOAT(WS-OBJ-INDEX)
                     ELSE
                        MOVE "ERR-OUT-OF-RANGE" TO WS-MAP-STATUS
                        MOVE "OBJECT-FLOAT-FIELD-OUT-OF-RANGE" TO WS-MAP-ERROR
                        GOBACK
                     END-IF
                  END-IF

                  IF WS-OBJ-IN-FLOAT(WS-OBJ-INDEX) > WS-OBJ-IN-FLOAT-MAX(WS-OBJ-INDEX)
                     IF WS-OBJ-CLIP = 'Y'
                        MOVE WS-OBJ-IN-FLOAT-MAX(WS-OBJ-INDEX) TO WS-OBJ-IN-FLOAT(WS-OBJ-INDEX)
                     ELSE
                        MOVE "ERR-OUT-OF-RANGE" TO WS-MAP-STATUS
                        MOVE "OBJECT-FLOAT-FIELD-OUT-OF-RANGE" TO WS-MAP-ERROR
                        GOBACK
                     END-IF
                  END-IF

                  COMPUTE WS-OBJ-OUT-VALUE(WS-OBJ-INDEX) =
                    WS-OUTPUT-MIN +
                    (
                      (WS-OBJ-IN-FLOAT(WS-OBJ-INDEX) - WS-OBJ-IN-FLOAT-MIN(WS-OBJ-INDEX))
                      / WS-FLOAT-SPAN
                    ) * WS-OUTPUT-SPAN
               ELSE IF WS-TYPE-CODE = 'B'
                  MOVE WS-OBJ-IN-BOOL(WS-OBJ-INDEX) TO WS-BOOL-VALUE
                  IF WS-BOOL-VALUE = '1' OR WS-BOOL-VALUE = 'Y' OR WS-BOOL-VALUE = 'T'
                     MOVE WS-OUTPUT-TRUE TO WS-OBJ-OUT-VALUE(WS-OBJ-INDEX)
                  ELSE IF WS-BOOL-VALUE = '0' OR WS-BOOL-VALUE = 'N' OR WS-BOOL-VALUE = 'F'
                     MOVE WS-OUTPUT-FALSE TO WS-OBJ-OUT-VALUE(WS-OBJ-INDEX)
                  ELSE
                     MOVE "ERR-TYPE" TO WS-MAP-STATUS
                     MOVE "OBJECT-BOOL-VALUE-MUST-BE-STRICT-TRUE-FALSE" TO WS-MAP-ERROR
                     GOBACK
                  END-IF
               ELSE IF WS-TYPE-CODE = 'Y'
                  MOVE WS-OBJ-IN-BYTES(WS-OBJ-INDEX)(1:1) TO WS-TEMP-BYTE
                  IF WS-TEMP-BYTE = SPACES
                     MOVE "ERR-EMPTY" TO WS-MAP-STATUS
                     MOVE "OBJECT-BYTES-FIELD-CANNOT-BE-EMPTY" TO WS-MAP-ERROR
                     GOBACK
                  END-IF

                  COMPUTE WS-BYTE-VALUE = FUNCTION ORD(WS-TEMP-BYTE)
                  IF WS-BYTE-VALUE < 0
                  OR WS-BYTE-VALUE > 255
                     MOVE "ERR-NON-BYTE" TO WS-MAP-STATUS
                     MOVE "OBJECT-BYTES-FIELD-MUST-BE-SINGLE-BYTE" TO WS-MAP-ERROR
                     GOBACK
                  END-IF

                  COMPUTE WS-OBJ-OUT-VALUE(WS-OBJ-INDEX) =
                    WS-OUTPUT-MIN +
                    (WS-BYTE-VALUE / 255.0) * WS-OUTPUT-SPAN
               ELSE
                  IF WS-OBJ-ALLOW-UNKNOWN = 'Y'
                     MOVE WS-OUTPUT-MIN TO WS-OBJ-OUT-VALUE(WS-OBJ-INDEX)
                  ELSE
                     MOVE "ERR-UNKNOWN-FIELD" TO WS-MAP-STATUS
                     MOVE "OBJECT-FIELD-TYPE-UNKNOWN" TO WS-MAP-ERROR
                     GOBACK
                  END-IF
               END-IF
           END-PERFORM.

           MOVE "OK" TO WS-MAP-STATUS.
           MOVE SPACES TO WS-MAP-ERROR.
           GOBACK.

       MAP-IMAGE-VALUE-SECTION.
           MOVE SPACES TO WS-MAP-STATUS WS-MAP-ERROR.
           COMPUTE WS-OUTPUT-SPAN = WS-OUTPUT-MAX - WS-OUTPUT-MIN.

           IF WS-OUTPUT-SPAN = 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "IMAGE-OUTPUT-RANGE-SPAN-MUST-BE-NON-ZERO" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-IMG-BYTES-COUNT < 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "IMAGE-BYTES-COUNT-MUST-NOT-BE-NEGATIVE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-IMG-ROWS < 0 OR WS-IMG-COLS < 0 OR WS-IMG-CHANNELS < 0
               MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
               MOVE "IMAGE-SHAPE-MUST-NOT-BE-NEGATIVE" TO WS-MAP-ERROR
               GOBACK
           END-IF.

           IF WS-IMG-ALLOW-EMPTY NOT = 'Y'
           AND WS-IMG-ALLOW-EMPTY NOT = 'N'
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "IMAGE-ALLOW-EMPTY-MUST-BE-Y-OR-N" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-IMG-CLIP NOT = 'Y'
           AND WS-IMG-CLIP NOT = 'N'
               MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
               MOVE "IMAGE-CLIP-MUST-BE-Y-OR-N" TO WS-MAP-ERROR
               GOBACK
           END-IF.

           IF WS-IMG-BYTES-COUNT > WS-IMG-OUT-LIMIT
              MOVE "ERR-IMAGE-SHAPE" TO WS-MAP-STATUS
              MOVE "IMAGE-BYTES-COUNT-MUST-NOT-EXCEED-IMAGE-OUTPUT-LIMIT" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-IMG-BYTES-COUNT = 0
              IF WS-IMG-ALLOW-EMPTY = 'Y'
                 MOVE "OK" TO WS-MAP-STATUS
                 MOVE 0 TO WS-IMG-OUT-COUNT
                 GOBACK
              END-IF
              MOVE "ERR-EMPTY" TO WS-MAP-STATUS
              MOVE "IMAGE-BYTES-CANNOT-BE-EMPTY" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           MOVE WS-IMG-ROWS TO WS-CALC-ROWS.
           MOVE WS-IMG-COLS TO WS-CALC-COLS.
           MOVE WS-IMG-CHANNELS TO WS-CALC-CHANNELS.
           MOVE WS-IMG-BYTES-COUNT TO WS-CALC-COUNT.

           EVALUATE WS-IMG-MODE
             WHEN "AUTO"
               IF WS-CALC-ROWS = 0 AND WS-CALC-COLS = 0 AND WS-CALC-CHANNELS = 0
                  MOVE 1 TO WS-CALC-CHANNELS
                  MOVE 0 TO WS-CALC-ROWS WS-CALC-COLS
                  COMPUTE WS-CALC-COUNT = WS-IMG-BYTES-COUNT
               ELSE
                  IF WS-CALC-ROWS <= 0 OR WS-CALC-COLS <= 0 OR WS-CALC-CHANNELS <= 0
                     MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
                     MOVE "IMAGE-AUTO-MODE-REQUIRES-ROWS-COLS-AND-CHANNELS" TO WS-MAP-ERROR
                     GOBACK
                  END-IF
               END-IF
             WHEN "RGB "
               MOVE 3 TO WS-CALC-CHANNELS
             WHEN "RGBA"
               MOVE 4 TO WS-CALC-CHANNELS
             WHEN OTHER
               MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
               MOVE "IMAGE-MODE-MUST-BE-AUTO-RGB-RGBA" TO WS-MAP-ERROR
               GOBACK
           END-EVALUATE.

           IF WS-CALC-CHANNELS <= 0
              MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
              MOVE "IMAGE-CHANNELS-MUST-BE-POSITIVE" TO WS-MAP-ERROR
              GOBACK
           END-IF.

           IF WS-IMG-MODE NOT = "AUTO"
              IF WS-CALC-ROWS <= 0 OR WS-CALC-COLS <= 0
                 MOVE "ERR-SCHEMA" TO WS-MAP-STATUS
                 MOVE "IMAGE-ROWS-COLS-MUST-BE-POSITIVE" TO WS-MAP-ERROR
                 GOBACK
              END-IF
           END-IF.

           IF WS-IMG-MODE = "AUTO"
              IF WS-IMG-ROWS = 0 AND WS-IMG-COLS = 0
                 CONTINUE
              ELSE
                 COMPUTE WS-CALC-COUNT = WS-CALC-ROWS * WS-CALC-COLS * WS-CALC-CHANNELS
                 IF WS-IMG-BYTES-COUNT NOT = WS-CALC-COUNT
                    MOVE "ERR-IMAGE-SHAPE" TO WS-MAP-STATUS
                    MOVE "IMAGE-SHAPE-MISMATCH-RGB-CELLS" TO WS-MAP-ERROR
                    GOBACK
                 END-IF
              END-IF
           ELSE
              COMPUTE WS-CALC-COUNT = WS-CALC-ROWS * WS-CALC-COLS * WS-CALC-CHANNELS
              IF WS-IMG-BYTES-COUNT NOT = WS-CALC-COUNT
                 MOVE "ERR-IMAGE-SHAPE" TO WS-MAP-STATUS
                 MOVE "IMAGE-SHAPE-MISMATCH-RGB-CELLS" TO WS-MAP-ERROR
                 GOBACK
              END-IF
           END-IF.

           MOVE 0 TO WS-IMG-OUT-COUNT
           MOVE 0 TO WS-IMG-INDEX
           MOVE 0 TO WS-BYTE-VALUE
           MOVE 1 TO WS-IMG-INDEX
           PERFORM VARYING WS-IMG-INDEX FROM 1 BY 1
                   UNTIL WS-IMG-INDEX > WS-IMG-BYTES-COUNT
               MOVE WS-IMG-BYTES-IN(WS-IMG-INDEX:1) TO WS-TEMP-BYTE
               COMPUTE WS-BYTE-VALUE = FUNCTION ORD(WS-TEMP-BYTE)
               IF WS-BYTE-VALUE < 0 OR WS-BYTE-VALUE > 255
                  MOVE "ERR-NON-BYTE" TO WS-MAP-STATUS
                  MOVE "IMAGE-NON-BYTE-PAYLOAD-REJECTED" TO WS-MAP-ERROR
                  GOBACK
               END-IF

               COMPUTE WS-IMG-OUT-VALUES(WS-IMG-INDEX) =
                 WS-OUTPUT-MIN + (WS-BYTE-VALUE / 255.0) * WS-OUTPUT-SPAN
               ADD 1 TO WS-IMG-OUT-COUNT
           END-PERFORM.

           MOVE "OK" TO WS-MAP-STATUS.
           MOVE SPACES TO WS-MAP-ERROR.
           GOBACK.

        GOBACK.
