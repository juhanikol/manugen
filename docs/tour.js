// Feature tour: one video stage, a list of steps. Only the active clip is loaded.
document.querySelectorAll("[data-tour]").forEach((tour) => {
  const base = tour.dataset.base || "assets/";
  const video = tour.querySelector("video");
  const steps = [...tour.querySelectorAll("[data-video]")];
  const out = (k) => tour.querySelector(`[data-${k}]`);
  const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  let i = 0, auto = !reduce, visible = false, selfPause = false, timer;

  const play = () => video.play().catch(() => {});
  const show = (n, start) => {
    clearTimeout(timer);
    i = (n + steps.length) % steps.length;
    const b = steps[i], name = b.dataset.video;
    steps.forEach((s) => s.removeAttribute("aria-current"));
    b.setAttribute("aria-current", "step");
    video.poster = base + name + ".jpg";
    video.src = base + name + ".mp4";
    video.setAttribute("aria-label", b.dataset.title);
    out("chapter").textContent = b.dataset.chapter;
    out("count").textContent = `${i + 1} / ${steps.length}`;
    out("title").textContent = b.dataset.title;
    out("text").textContent = b.nextElementSibling.textContent;
    if (start) play();
  };

  steps.forEach((b, n) => b.addEventListener("click", () => { auto = true; show(n, true); }));
  out("prev").addEventListener("click", () => show(i - 1, true));
  out("next").addEventListener("click", () => show(i + 1, true));
  video.addEventListener("ended", () => {
    if (auto && i < steps.length - 1) timer = setTimeout(() => show(i + 1, visible), 900);
  });
  video.addEventListener("pause", () => {
    if (!selfPause && !video.ended) auto = false; // the viewer paused: stop advancing
    selfPause = false;
  });

  new IntersectionObserver(([e]) => {
    visible = e.isIntersecting;
    if (visible && auto && video.paused && !video.ended) play();
    if (!visible && !video.paused) { selfPause = true; video.pause(); }
  }, { threshold: 0.5 }).observe(video);

  show(0, false);
});
