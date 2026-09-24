const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      minlength: [2, 'Name must be at least 2 characters'],
      maxlength: [100, 'Name must not exceed 100 characters'],
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email'],
    },
    passwordHash: {
      type: String,
      required: true,
      select: false, // never returned in queries by default
    },

    // ── Email verification ─────────────────────────────────────────────────
    emailVerified: {
      type: Boolean,
      default: false,
    },
    verificationTokenHash: {
      type: String,
      select: false,
    },
    verificationTokenExpires: {
      type: Date,
      select: false,
    },

    // ── Password reset ─────────────────────────────────────────────────────
    resetPasswordTokenHash: {
      type: String,
      select: false,
    },
    resetPasswordTokenExpires: {
      type: Date,
      select: false,
    },
  },
  {
    timestamps: true,
  }
);

// ── Pre-save hook: hash passwordHash when modified ─────────────────────────
userSchema.pre('save', async function (next) {
  if (!this.isModified('passwordHash')) return next();
  const salt = await bcrypt.genSalt(12);
  this.passwordHash = await bcrypt.hash(this.passwordHash, salt);
  next();
});

// ── Instance methods ───────────────────────────────────────────────────────

userSchema.methods.comparePassword = async function (plainPassword) {
  return bcrypt.compare(plainPassword, this.passwordHash);
};

userSchema.methods.compareVerificationToken = async function (rawToken) {
  if (!this.verificationTokenHash) return false;
  return bcrypt.compare(rawToken, this.verificationTokenHash);
};

userSchema.methods.compareResetToken = async function (rawToken) {
  if (!this.resetPasswordTokenHash) return false;
  return bcrypt.compare(rawToken, this.resetPasswordTokenHash);
};

// Never expose sensitive fields in JSON output
userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.passwordHash;
  delete obj.verificationTokenHash;
  delete obj.verificationTokenExpires;
  delete obj.resetPasswordTokenHash;
  delete obj.resetPasswordTokenExpires;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
