function adjustPrice(current, adjustment) {
  const value = Number(current);
  if (!Number.isFinite(value) || value <= 0) return null;

  let next;
  if (adjustment.type === 'percentage') {
    next =
      adjustment.direction === 'up'
        ? value * (1 + adjustment.amount / 100)
        : value * (1 - adjustment.amount / 100);
  } else {
    next =
      adjustment.direction === 'up'
        ? value + adjustment.amount
        : value - adjustment.amount;
  }
  next = Math.round((next + Number.EPSILON) * 100) / 100;
  return next > 0 ? next : null;
}

module.exports = { adjustPrice };
