export class MotivatingSlogan {
  static randomPhrase() {
    const phrases = [
      "Stay strong and persevere.",
      "Don't give up.",
      "Keep pushing forward.",
      "Stay determined.",
      "Keep up the good work.",
      "You've got this.",
      "Stay motivated and don't quit.",
      "Keep on moving forward.",
      "Don't lose hope.",
      "Continue with your efforts.",
    ]
    const index = Math.floor(Math.random() * phrases.length);

    return phrases[index];
  }

  static randomQuote() {
    const quotes = [
      {
        text: "It always seems impossible until it’s done.",
        author: "Nelson Mandela",
      }, {
        text: "The journey of a thousand miles begins with one step.",
        author: "Lao Tzu",
      }, {
        text: "The secret of getting ahead is getting started.",
        author: "Mark Twain",
      }, {
        text: "How long should you try? Until.",
        author: "Jim Rohn",
      }, {
        text: "Winners never quit, and quitters never win.",
        author: "Vince Lombardi",
      }, {
        text: "Believe you can, and you’re halfway there.",
        author: "Theodore Roosevelt",
      }, {
        text: "The greater the obstacle, the more glory in overcoming it.",
        author: "Molière",
      }, {
        text: "It does not matter how slowly you go as long as you do not stop.",
        author: "Confucius",
      }, {
        text: "Successful men and women keep moving. They make mistakes, but they don’t quit.",
        author: "Conrad Hilton",
      }, {
        text: "Fall seven times; stand up eight.",
        author: "Japanese proverb",
      },
    ];
    const index = Math.floor(Math.random() * quotes.length);

    return `${quotes[index].text} --- ${quotes[index].author}`;
  }
}
